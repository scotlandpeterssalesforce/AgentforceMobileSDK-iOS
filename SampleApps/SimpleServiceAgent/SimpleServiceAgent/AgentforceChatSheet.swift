//
//  AgentforceChatSheet.swift
//  SimpleServiceAgent
//
//  Hosts the SDK-provided AgentforceChatView inside a presented sheet, for
//  either the Chat or Voice experience. The view is created once on appear and
//  the session is torn down on dismiss.
//

import SwiftUI
import AgentforceSDK

struct AgentforceChatSheet: View {
    let mode: AgentMode
    let settings: AppSettings
    @ObservedObject var session: AgentforceSessionManager
    let onClose: () -> Void

    @State private var chatView: AgentforceChatView?
    @State private var didFail = false

    var body: some View {
        Group {
            if let chatView {
                chatView
            } else if didFail {
                failureView
            } else {
                ProgressView("Starting…")
            }
        }
        .onAppear(perform: startIfNeeded)
        .onDisappear { session.end() }
    }

    private func startIfNeeded() {
        guard chatView == nil, !didFail else { return }
        if let view = session.makeChatView(settings: settings, mode: mode, onClose: onClose) {
            chatView = view
        } else {
            didFail = true
        }
    }

    private var failureView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Couldn’t start the Agentforce session.")
                .font(.headline)
            Text("Double-check the Service API URL, Organization ID, and Developer Name.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Close", action: onClose)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
