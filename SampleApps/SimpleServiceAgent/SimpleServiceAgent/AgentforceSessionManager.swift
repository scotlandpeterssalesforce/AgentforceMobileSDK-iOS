//
//  AgentforceSessionManager.swift
//  SimpleServiceAgent
//
//  Owns the AgentforceSDK objects for a single presented session: it builds a
//  guest-authenticated configuration from AppSettings, creates the client and
//  conversation, and hands back the SDK's chat view. The client and
//  conversation must be retained for the life of the session, which is why
//  they live here rather than in a transient view.
//

import SwiftUI
import AgentforceSDK
import AgentforceService
import SalesforceUser

/// Which experience to launch. Maps onto the SDK's `AgentforceViewMode`.
enum AgentMode: String, Identifiable {
    case chat
    case voice

    var id: String { rawValue }
    var viewMode: AgentforceViewMode { self == .voice ? .voice : .chat }
}

/// Minimal guest credential provider. Returns `.Guest` credentials keyed to the
/// org's My Domain URL, which hosts the `/agentforce/bootstrap` endpoint the SDK
/// calls to mint a guest access token — so no user login is required. The
/// protocol's other requirement (`fetchMIAWJWTForPassthrough`) has a default
/// implementation that guest access does not need.
struct GuestCredentialProvider: AgentforceAuthCredentialProviding {
    let domainURL: String

    func getAuthCredentials() -> AgentforceAuthCredentials {
        .Guest(url: domainURL)
    }
}

@MainActor
final class AgentforceSessionManager: ObservableObject {

    // Retained for the lifetime of the presented session; releasing these ends
    // the conversation.
    private var client: AgentforceClient?
    private var conversation: (any AgentConversation)?

    /// Builds a fresh guest-authenticated session and returns the SDK's chat
    /// view configured for `mode`. Returns `nil` if the settings are incomplete
    /// or the SDK fails to create the view.
    func makeChatView(settings: AppSettings,
                      mode: AgentMode,
                      onClose: @escaping () -> Void) -> AgentforceChatView? {
        let domainURL = settings.domainURL.trimmed
        let agentID = settings.agentID.trimmed
        let sfapURL = settings.sfapURL.trimmed
        let tenantID = settings.tenantID.trimmed
        guard !domainURL.isEmpty, !agentID.isEmpty, !sfapURL.isEmpty else {
            return nil
        }

        // Guest access uses the "full config" mode: an empty guest `User`, a
        // credential provider that vends `.Guest(url:)`, and an
        // `AgentforceConnectionInfo` pointing at the SFAP endpoint. The Domain
        // URL doubles as the `forceConfigEndpoint` (voice reaches the org
        // through it) and the guest bootstrap URL.
        let configuration = AgentforceConfiguration(
            user: User(userId: "", org: Org(id: ""), username: "", displayName: ""),
            authProvider: GuestCredentialProvider(domainURL: domainURL),
            forceConfigEndpoint: domainURL,
            agentforceFeatureFlagSettings: AgentforceFeatureFlagSettings(enableVoice: true),
            agentforceConnectionInfo: AgentforceConnectionInfo(sfapURL: sfapURL, tenantId: tenantID),
            salesforceNetwork: nil,
            salesforceNavigation: nil
        )

        let client = AgentforceClient(mode: .fullConfig(configuration))
        let conversation = client.startAgentforceConversation(forAgentId: agentID)
        self.client = client
        self.conversation = conversation

        do {
            return try client.createAgentforceChatView(
                conversation: conversation,
                initialMode: mode.viewMode,
                delegate: nil,
                showTopBar: true,
                onContainerClose: onClose
            )
        } catch {
            end()
            return nil
        }
    }

    /// Tears down the current session, releasing the SDK objects.
    func end() {
        conversation = nil
        client = nil
    }
}
