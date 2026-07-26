# HuanGeSdk for iOS

HuanGeSdk is a closed-source binary Swift package for connecting to and operating supported HuanGe BLE recording devices.

The SDK provides BLE scanning and connection management, device information queries, recording control, raw realtime audio, device file operations, button configuration, and OTA firmware transfer.

[中文接入文档](docs/huange_sdk_integration_zh.md)

## Requirements

- iOS 16.0 or later
- Swift 6.2 or later
- A supported physical HuanGe BLE device
- An `NSBluetoothAlwaysUsageDescription` entry in the integrating app

All BLE work, protocol parsing, and SDK event production run on the SDK's dedicated serial background queue. The SDK does not switch events to the main actor. The integrating app owns UI state and decides where events are consumed.

## Installation

In Xcode, select **File > Add Package Dependencies...** and enter:

```text
https://github.com/caitunai/HuanGe-iOS-sdk.git
```

Select the required version and add the `HuanGeSdk` product to your app target.

Then import the SDK:

```swift
import HuanGeSdk
```

Add a Bluetooth usage description to the app's `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connect to the recording device and transfer audio and files.</string>
```

## Create a Client and Consume Events

Keep one long-lived `HuanGeClient` for the device workflow. A UI-facing model can consume SDK events on `MainActor`:

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

Do not assume that SDK events arrive on the main actor. Non-UI integrations may consume the streams from their own actor or background task.

## Scanning and Connecting

```swift
client.startScanning()
client.stopScanning()
client.connect(to: device)
client.disconnect()
```

Every scan stops automatically when `HuanGeConfiguration.scanTimeout` expires. The default timeout is 15 seconds.

`HuanGeDevice.macAddress` is parsed from the final six bytes of Manufacturer Specific Data in the BLE advertisement. It is not derived from `CBPeripheral.identifier`.

## Device Binding and Authentication

Binding uses an application-provided 16-byte key. The app only supplies the key; HuanGeSdk queries the binding state and, when authentication is required, generates a fresh 16-byte nonce and its HMAC-SHA256 value automatically.

Start binding or authentication explicitly after the connection becomes ready. HuanGeSdk does not automatically send binding, authentication, or other control commands after connecting.

```swift
// Load exactly 16 bytes from Keychain or another application-owned secure store.
let bindingKey: Data = try await bindingKeyStore.key(for: device.id)

do {
    let result = try await client.bindOrVerifyDevice(using: bindingKey)

    switch result {
    case .bound:
        print("The key was accepted and the device is now bound.")
    case .verified:
        print("The existing binding was authenticated.")
    }
} catch HuanGeError.bindingVerificationFailed {
    print("The device rejected the nonce signature. Check the stored key.")
} catch {
    print("Binding operation failed: \(error.localizedDescription)")
}
```

`bindOrVerifyDevice(using:)` performs the complete recommended flow:

- For an unbound device, it sends the supplied key and returns `.bound` after the device accepts it.
- For a bound device, it never writes the key again. It performs nonce/HMAC-SHA256 authentication and returns `.verified` on success.
- A key with any length other than 16 bytes throws `HuanGeError.invalidBindingKeyLength`.
- An incorrect key used with a bound device throws `HuanGeError.bindingVerificationFailed`.

The lower-level APIs are available when the app needs an explicit workflow:

```swift
let state = try await client.getDeviceBindingState()

if state == .bound {
    try await client.verifyDeviceBinding(using: bindingKey)
}
```

`verifyDeviceBinding(using:)` only authenticates an already-bound device and never writes a key. Calling it for an unbound device throws `HuanGeError.deviceNotBound`. Binding state responses are also reported through `HuanGeEvent.deviceBindingStateChanged`.

Persist the key before binding and associate it with the correct device. Losing the key prevents future authentication until the device is forcibly unbound using its hardware controls. Production apps should use Keychain or an appropriately secured backend; do not store binding keys in source code, logs, `UserDefaults`, or the caches directory. The Demo app's cache-based key history exists only for hardware testing and is not a production storage design.

To confirm that authentication rejects an incorrect key without changing the device binding, alter a copy and call the verification-only API:

```swift
var incorrectKey = bindingKey
incorrectKey[incorrectKey.startIndex] ^= 0xFF

do {
    try await client.verifyDeviceBinding(using: incorrectKey)
    assertionFailure("The device unexpectedly accepted an incorrect key.")
} catch HuanGeError.bindingVerificationFailed {
    // Expected: the device rejected the HMAC-SHA256 result.
}
```

## Device Queries and Controls

Once the device is connected and notifications are enabled, use the async APIs:

```swift
do {
    async let battery = client.getBatteryState()
    async let storage = client.getStorageCapacity()
    async let firmware = client.getFirmwareVersion()

    let result = try await (battery, storage, firmware)
    print(result)
} catch {
    print("Device request failed: \(error)")
}
```

Common operations include:

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

When a hardware button starts or controls recording, the SDK automatically acknowledges the device according to the protocol and reports the action through `HuanGeEvent.hardwareRecordingActionReceived`.

## Raw Realtime Audio

Consume raw realtime audio from `realtimeTranscriptionAudio`:

```swift
let audioTask = Task { [audio = client.realtimeTranscriptionAudio] in
    for await data in audio {
        await audioProcessor.append(data)
    }
}
```

The current hardware uses JieLi-compatible headerless Opus at 16 kHz, mono. The SDK intentionally does not split Opus frames. Do not assume one BLE notification is one complete audio frame. The app owns buffering, frame parsing, decoding, and transcription upload.

## Device Files

Query and manage device files with:

```swift
let files = try await client.getDeviceFiles()

if let file = files.first {
    let completion = try await client.importFile(file)
    print("Imported \(completion.byteCount) bytes")
}
```

The SDK does not create or save local files. Consume `fileImportData` and store or process each `HuanGeFileImportChunk` in the app:

```swift
let fileTask = Task { [chunks = client.fileImportData] in
    for await chunk in chunks {
        await fileWriter.append(chunk)
    }
}
```

Available file operations:

- `getDeviceFiles()`
- `importFile(_:resumeFromOffset:)`
- `cancelFileImport()`
- `deleteFile(_:)`
- `deleteAllFiles()`

Some firmware versions do not implement delete-all. Validate this operation with the target hardware.

## OTA Firmware Transfer

Firmware download is the app's responsibility. Pass downloaded binary data or a local file URL to the SDK:

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

Or transfer a local file:

```swift
try await client.startOTAUpdate(at: localFirmwareURL)
```

The SDK activates OTA mode and handles raw transfer, progress, timeouts, and OTA events on background queues. Call `cancelOTAUpdate()` to cancel an active update.

OTA transfer must be validated with the exact target hardware and firmware. A confirmed file transfer does not by itself prove that the device installed the firmware or restarted successfully.

## Integration Responsibilities

The integrating app is responsible for:

- UI state and actor switching
- Bluetooth permission messaging
- Secure generation, persistence, recovery, and device association of binding keys
- Raw audio buffering, decoding, and transcription
- Persisting or processing imported file chunks
- Downloading and validating OTA firmware
- Presenting user-facing errors and diagnostics
- Cancelling stream-consumer tasks when they are no longer needed
- Validating all critical workflows with physical hardware

## License

See [LICENSE](LICENSE).
