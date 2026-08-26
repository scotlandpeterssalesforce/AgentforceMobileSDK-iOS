# SimpleServiceAgent

A minimal SwiftUI sample app that launches the **AgentforceSDK Service Agent**
experience — Voice or Chat — from three user-supplied configuration values.

<p align="center">Configure → Launch Voice / Launch Chat</p>

## What it does

- One screen with three text fields: **Service API URL**, **Organization ID**,
  and **Developer Name**.
- Values are saved to `UserDefaults` as you type and restored on next launch.
- **Launch Voice** and **Launch Chat** buttons stay disabled until all three
  fields are filled in.
- Each button presents the SDK's `AgentforceChatView` in a sheet — Chat in text
  mode, Voice in voice mode.

The three fields map directly onto the SDK's Service Agent configuration:

| Field | `ServiceAgentConfiguration` parameter |
|---|---|
| Developer Name | `esDeveloperName` |
| Organization ID | `organizationId` |
| Service API URL | `serviceApiURL` |

## Requirements

- Xcode 16 or newer (developed against Xcode 26).
- iOS 17.0+ deployment target.
- Network access on first build to resolve the Swift packages.

## How it's wired up

The app depends on the published AgentforceSDK package over Swift Package
Manager (no CocoaPods):

- **Package:** `https://github.com/salesforce/AgentforceMobileSDK-iOS`
- **Rule:** Up to Next Major from **18.33.14** (latest stable at time of writing)
- **Products used:** `AgentforceSDK` (chat) and `AgentforceVoice` (voice engine)

`AgentforceService` and the rest of the dependency graph resolve
automatically — do **not** add `AgentforceMobileService-iOS` as a separate
package; it is bundled inside the SDK.

Session setup lives in
[`AgentforceSessionManager.swift`](SimpleServiceAgent/AgentforceSessionManager.swift):

```swift
let configuration = ServiceAgentConfiguration(
    esDeveloperName: developerName,
    organizationId: organizationID,
    serviceApiURL: serviceAPIURL,
    forceConfigEndPoint: "",                                    // see note below
    featureFlags: AgentforceFeatureFlagSettings(enableVoice: true)
)
let client = AgentforceClient(mode: .serviceAgent(configuration))
let conversation = client.startAgentforceConversation(forESDeveloperName: developerName)
let chatView = try client.createAgentforceChatView(
    conversation: conversation,
    initialMode: mode.viewMode,     // .chat or .voice
    delegate: nil,
    showTopBar: true,
    onContainerClose: onClose
)
```

## Running

1. Open `SimpleServiceAgent.xcodeproj` in Xcode and let it resolve packages.
2. Select an iOS Simulator (or a device — see Signing) and Run.
3. Enter your deployment's Service API URL, Organization ID, and Developer Name.
4. Tap **Launch Chat** or **Launch Voice**.

Or from the command line:

```sh
xcodebuild build \
  -project SimpleServiceAgent.xcodeproj \
  -scheme SimpleServiceAgent \
  -destination 'generic/platform=iOS Simulator'
```

### Signing

The project uses **Automatic** signing with no development team baked in, so it
builds for the Simulator out of the box. To run on a physical device, select the
target in Xcode and choose your team under *Signing & Capabilities*.

## Permissions (Voice)

Voice requires microphone and speech-recognition access, declared in
[`Info.plist`](SimpleServiceAgent/Info.plist):

- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `UIBackgroundModes` → `audio` (keeps a call alive during brief backgrounding)

## Notes & limitations

- **`forceConfigEndPoint` is left empty.** The SDK derives it from the Service
  API URL (SCRT2 naming convention). Branding, mobile types, and image loading
  rely on this; if branded assets fail to load, pass your org's My Domain URL
  (e.g. `https://myorg.my.salesforce.com`) here.
- This sample targets **unverified Service Agents**, so it does not implement an
  auth credential provider. Verified/authenticated agents would additionally
  require an `AgentforceAuthCredentialProviding` implementation.
- Intentionally out of scope for this first cut: OAuth login, theming/view
  providers, attachments/multi-modal input, and the iOS 26 floating launcher.
