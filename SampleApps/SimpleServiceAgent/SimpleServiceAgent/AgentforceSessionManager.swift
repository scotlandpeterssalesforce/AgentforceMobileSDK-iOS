//
//  AgentforceSessionManager.swift
//  SimpleServiceAgent
//
//  Owns the AgentforceSDK objects for a single presented session: it builds a
//  Service Agent configuration from AppSettings, creates the client and
//  conversation, and hands back the SDK's chat view. The client and
//  conversation must be retained for the life of the session, which is why
//  they live here rather than in a transient view.
//

import SwiftUI
import AgentforceSDK

/// Which experience to launch. Maps onto the SDK's `AgentforceViewMode`.
enum AgentMode: String, Identifiable {
    case chat
    case voice

    var id: String { rawValue }
    var viewMode: AgentforceViewMode { self == .voice ? .voice : .chat }
}

@MainActor
final class AgentforceSessionManager: ObservableObject {

    // Retained for the lifetime of the presented session; releasing these ends
    // the conversation.
    private var client: AgentforceClient?
    private var conversation: (any AgentConversation)?

    /// Builds a fresh Service Agent session and returns the SDK's chat view
    /// configured for `mode`. Returns `nil` if the settings are incomplete or
    /// the SDK fails to create the view.
    func makeChatView(settings: AppSettings,
                      mode: AgentMode,
                      onClose: @escaping () -> Void) -> AgentforceChatView? {
        let developerName = settings.developerName.trimmed
        let organizationID = settings.organizationID.trimmed
        let serviceAPIURL = settings.serviceAPIURL.trimmed
        guard !developerName.isEmpty, !organizationID.isEmpty, !serviceAPIURL.isEmpty else {
            return nil
        }

        // `forceConfigEndPoint` is the org's My Domain URL used for branding,
        // mobile types, and image loading. We leave it empty so the SDK derives
        // it from the Service API URL (SCRT2 naming convention); supply a real
        // org URL here if branded assets fail to load.
        let configuration = ServiceAgentConfiguration(
            esDeveloperName: developerName,
            organizationId: organizationID,
            serviceApiURL: serviceAPIURL,
            forceConfigEndPoint: "",
            featureFlags: AgentforceFeatureFlagSettings(enableVoice: true)
        )

        let client = AgentforceClient(mode: .serviceAgent(configuration))
        let conversation = client.startAgentforceConversation(forESDeveloperName: developerName)
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
