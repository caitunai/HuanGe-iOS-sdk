# HuanGeSdk iOS 应用接入指南

HuanGeSdk 是面向环格 BLE 录音设备的闭源二进制 Swift Package，提供 BLE 扫描与连接、设备信息查询、录音控制、原始实时音频流、设备文件操作、按键设置和 OTA 固件传输能力。

## 1. 接入要求

- iOS 16.0 或更高版本。
- Swift 6.2 或更高版本。
- 使用支持 HuanGeSdk 的真实 BLE 外设进行验证。
- App 的 `Info.plist` 必须配置蓝牙使用说明。

HuanGeSdk 的 BLE 操作、协议解析和事件生产均运行在 SDK 专用的后台串行队列。SDK 不会自动将事件切换到主线程；接入 App 负责 UI 状态，并自行决定在哪个 Actor 或队列消费事件。

## 2. 通过 Swift Package Manager 添加 SDK

在 Xcode 中选择 **File > Add Package Dependencies...**，输入仓库地址：

```text
https://github.com/caitunai/HuanGe-iOS-sdk.git
```

选择需要的版本，并为 App Target 添加 `HuanGeSdk` Product。

在业务代码中导入模块：

```swift
import HuanGeSdk
```

在 App 的 `Info.plist` 中添加蓝牙权限说明：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>用于连接录音设备并传输音频与文件。</string>
```

## 3. 创建客户端并消费事件

建议在完整的设备操作流程中长期持有同一个 `HuanGeClient`。UI 层可以使用 `@MainActor @Observable` 模型消费 SDK 事件：

```swift
import HuanGeSdk
import Observation

@MainActor
@Observable
final class DeviceModel {
    private(set) var devices: [HuanGeDevice] = []
    private(set) var connectionState: HuanGeConnectionState = .disconnected

    private let client: HuanGeClient
    private var eventTask: Task<Void, Never>?

    init() {
        var configuration = HuanGeConfiguration()
        configuration.scanTimeout = .seconds(15)
        client = HuanGeClient(configuration: configuration)

        eventTask = Task { [weak self, events = client.events] in
            for await event in events {
                guard !Task.isCancelled else {
                    return
                }
                self?.handle(event)
            }
        }
    }

    func startScanning() {
        client.startScanning()
    }

    func connect(to device: HuanGeDevice) {
        client.connect(to: device)
    }

    func disconnect() {
        client.disconnect()
    }

    private func handle(_ event: HuanGeEvent) {
        switch event {
        case .deviceDiscovered(let device):
            if let index = devices.firstIndex(where: { $0.id == device.id }) {
                devices[index] = device
            } else {
                devices.append(device)
            }
        case .connectionStateChanged(let state):
            connectionState = state
        case .diagnostic(let diagnostic):
            print(diagnostic.message)
        default:
            break
        }
    }
}
```

App 不应假设 SDK 事件位于主线程。非 UI 业务也可以在自定义 Actor 或后台任务中消费事件流。

## 4. BLE 扫描与连接

```swift
client.startScanning()
client.stopScanning()
client.connect(to: device)
client.disconnect()
```

每次扫描到达 `HuanGeConfiguration.scanTimeout` 后都会自动停止，默认扫描超时时间为 15 秒。

`HuanGeDevice.macAddress` 来自 BLE 广播 Manufacturer Specific Data 最后 6 个字节，不是 `CBPeripheral.identifier`。如果后续广播未携带 Manufacturer Specific Data，SDK 会保留此前解析到的 MAC 地址。

## 5. 查询与控制设备

设备连接并启用通知后，可以使用 async/await 接口：

```swift
do {
    async let battery = client.getBatteryState()
    async let storage = client.getStorageCapacity()
    async let firmware = client.getFirmwareVersion()

    let result = try await (battery, storage, firmware)
    print(result)
} catch {
    print("设备请求失败：\(error)")
}
```

常用接口包括：

- `getBatteryState()`
- `getStorageCapacity()`
- `synchronizeTime(_:)`
- `getFirmwareVersion()`
- `getAuthorizationCode()`
- `getRecordingInformation()`
- `getButtonConfiguration()`
- `setRecordingButtonGesture(_:)`
- `setPauseButtonGesture(_:)`
- `startRealtimeTranscription()`
- `pauseRealtimeTranscription()`
- `resumeRealtimeTranscription()`
- `stopRealtimeTranscription()`

硬件按键发起或控制录音时，SDK 会按照协议自动回复设备，并通过 `HuanGeEvent.hardwareRecordingActionReceived` 将操作状态上报给 App。

## 6. 原始实时音频流

通过 `realtimeTranscriptionAudio` 消费原始实时音频：

```swift
let audioTask = Task { [audio = client.realtimeTranscriptionAudio] in
    for await data in audio {
        await audioProcessor.append(data)
    }
}
```

当前硬件使用兼容杰理的无头 Opus、16 kHz、单声道音频。SDK 不会对收到的数据进行 Opus 拆帧。App 不应假设每个 BLE 通知都是一个完整音频帧，必须根据实际设备协议自行完成缓存、拆帧、解码或上传转写服务。

## 7. 设备文件操作

获取并导入设备文件：

```swift
let files = try await client.getDeviceFiles()

if let file = files.first {
    let completion = try await client.importFile(file)
    print("已导入 \(completion.byteCount) 字节")
}
```

SDK 不会创建或保存本地文件。App 必须消费 `fileImportData`，并自行保存或处理每个 `HuanGeFileImportChunk`：

```swift
let fileTask = Task { [chunks = client.fileImportData] in
    for await chunk in chunks {
        await fileWriter.append(chunk)
    }
}
```

可用的文件接口：

- `getDeviceFiles()`
- `importFile(_:resumeFromOffset:)`
- `cancelFileImport()`
- `deleteFile(_:)`
- `deleteAllFiles()`

部分固件版本未实现删除全部文件功能，使用前必须在目标硬件上验证。

## 8. OTA 固件传输

网络下载属于 App 层职责。App 下载并校验固件后，将二进制数据或本地文件 URL 传给 SDK：

```swift
let (firmware, response) = try await URLSession.shared.data(from: firmwareURL)

guard let response = response as? HTTPURLResponse,
      200 ..< 300 ~= response.statusCode else {
    throw URLError(.badServerResponse)
}

try await client.startOTAUpdate(
    firmware: firmware,
    fileName: "app_temp_upgrade.up"
)
```

也可以传入本地文件：

```swift
try await client.startOTAUpdate(at: localFirmwareURL)
```

SDK 会自动激活 OTA 模式，并在后台处理原始数据传输、进度、超时和 OTA 事件。调用 `cancelOTAUpdate()` 可以取消正在进行的升级。

OTA 必须使用对应的目标硬件和固件进行验证。设备确认完整接收文件，并不能单独证明设备已经成功安装固件或完成重启。

## 9. App 与 SDK 的职责边界

接入 App 负责：

- UI 状态管理以及需要时切换到 `MainActor`。
- 蓝牙权限说明和用户提示。
- 原始音频缓存、拆帧、解码和转写处理。
- 保存或处理 SDK 输出的文件数据块。
- 下载与校验 OTA 固件。
- 面向用户的错误提示与诊断日志展示。
- 在业务结束时取消事件、音频和文件流消费任务。
- 使用真实 BLE 外设验证全部关键功能。

HuanGeSdk 负责：

- BLE 扫描、连接、断开、服务发现、特征发现与通知。
- BLE 协议数据发送、接收和解析。
- 自动扫描超时、指令超时和文件导入空闲超时。
- 产生强类型、可发送的 SDK 事件与模型。
- OTA 模式激活及固件原始数据传输。

## 10. 真机验收清单

- 蓝牙权限拒绝、受限和已授权状态均有合理 UI。
- 扫描会按配置超时自动停止。
- 能显示设备名称、RSSI 和正确的广播 MAC 地址。
- 连接、断开和重新连接状态正确。
- 电量、存储空间、固件版本、授权码和时间同步工作正常。
- App 能持续消费原始实时音频，且不会阻塞 UI。
- 文件列表、删除和导入工作正常，导入文件由 App 保存。
- OTA 固件由 App 下载，SDK 能接收 `Data` 或本地 URL 并上报进度。
- 全部关键功能均使用真实 BLE 外设完成验证。
