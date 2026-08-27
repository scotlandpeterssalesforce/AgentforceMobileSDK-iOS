# SimpleServiceAgent

A minimal SwiftUI sample app that launches the **AgentforceSDK** experience —
Voice or Chat — using **guest authentication**, from a few user-supplied
configuration values. No user login is required: the SDK mints a guest token
from the org's bootstrap endpoint.

<p align="center">Configure → Launch Voice / Launch Chat</p>

## What it does

- One screen with three required text fields — **Domain URL**, **Agent ID**,
  **SFAP URL** — plus an optional **Tenant ID**.
- Values are saved to `UserDefaults` as you type and restored on next launch.
- **SFAP URL** is pre-filled with `https://api.salesforce.com` and can be edited.
- **Launch Voice** and **Launch Chat** buttons stay disabled until the three
  required fields are filled in.
- Each button presents the SDK's `AgentforceChatView` in a sheet — Chat in text
  mode, Voice in voice mode.

The fields drive an `AgentforceConfiguration` used in guest (`.fullConfig`) mode:

| Field | Where it goes |
|---|---|
| Domain URL | `AgentforceAuthCredentials.Guest(url:)` **and** `forceConfigEndpoint` |
| Agent ID | `startAgentforceConversation(forAgentId:)` |
| SFAP URL | `AgentforceConnectionInfo.sfapURL` |
| Tenant ID | `AgentforceConnectionInfo.tenantId` |

**Domain URL** is a valid `https://<mydomain>.my.salesforce.com` that hosts the
`/agentforce/bootstrap` guest endpoint (which mints the token). **Agent ID** is
passed as the `agentid` query parameter and used for the session. **SFAP URL**
is where API and voice calls go (defaults to `https://api.salesforce.com`).

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
package; it is bundled inside the SDK. The guest types (`User`, `Org`,
`AgentforceAuthCredentials`, `AgentforceConnectionInfo`) come from the
transitive `SalesforceUser` and `AgentforceService` modules, which are
importable without declaring them as separate packages.

Session setup lives in
[`AgentforceSessionManager.swift`](SimpleServiceAgent/AgentforceSessionManager.swift):

```swift
// A guest credential provider simply vends `.Guest(url:)`:
struct GuestCredentialProvider: AgentforceAuthCredentialProviding {
    let domainURL: String
    func getAuthCredentials() -> AgentforceAuthCredentials { .Guest(url: domainURL) }
}

let configuration = AgentforceConfiguration(
    user: User(userId: "", org: Org(id: ""), username: "", displayName: ""),  // empty guest user
    authProvider: GuestCredentialProvider(domainURL: domainURL),
    forceConfigEndpoint: domainURL,                                            // My Domain URL
    agentforceFeatureFlagSettings: AgentforceFeatureFlagSettings(enableVoice: true),
    agentforceConnectionInfo: AgentforceConnectionInfo(sfapURL: sfapURL, tenantId: tenantID),
    salesforceNetwork: nil,
    salesforceNavigation: nil
)
let client = AgentforceClient(mode: .fullConfig(configuration))
let conversation = client.startAgentforceConversation(forAgentId: agentID)
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
3. Enter your org's Domain URL and target Agent ID (SFAP URL is pre-filled).
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

- **The Domain URL is used twice.** It is both the guest credential URL
  (`AgentforceAuthCredentials.Guest(url:)`, which the SDK calls to bootstrap a
  guest token) and the `forceConfigEndpoint`. **Voice connects to this org
  endpoint directly**, so it must be a valid `https://<mydomain>.my.salesforce.com`.
- This sample uses **guest authentication**, so its `AgentforceAuthCredentialProviding`
  implementation just returns `.Guest(url:)` — no OAuth login or token refresh.
  Authenticated agents would return `.OAuth`/`.OrgJWT` credentials instead.
- Intentionally out of scope for this first cut: OAuth login, theming/view
  providers, attachments/multi-modal input, and the iOS 26 floating launcher.
