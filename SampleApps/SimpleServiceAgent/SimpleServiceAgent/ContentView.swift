//
//  ContentView.swift
//  SimpleServiceAgent
//
//  The single configuration screen: three persisted text fields plus the
//  Launch Voice / Launch Chat buttons, which are enabled once all fields are
//  filled in.
//

import SwiftUI

struct ContentView: View {
    @State private var settings = AppSettings()
    @StateObject private var session = AgentforceSessionManager()
    @State private var launch: AgentMode?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledField(title: "Service API URL",
                                 prompt: "https://…",
                                 text: $settings.serviceAPIURL,
                                 keyboard: .URL)
                    LabeledField(title: "Organization ID",
                                 prompt: "00Dxx0000000000",
                                 text: $settings.organizationID)
                    LabeledField(title: "Developer Name",
                                 prompt: "Agent developer name",
                                 text: $settings.developerName)
                } header: {
                    Text("Agent Configuration")
                } footer: {
                    Text("These values are saved on this device and reused next time.")
                }

                Section {
                    Button {
                        launch = .voice
                    } label: {
                        Label("Launch Voice", systemImage: "waveform")
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        launch = .chat
                    } label: {
                        Label("Launch Chat", systemImage: "bubble.left.and.bubble.right")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!settings.isComplete)
            }
            .navigationTitle("Simple Service Agent")
        }
        .sheet(item: $launch) { mode in
            AgentforceChatSheet(mode: mode,
                                settings: settings,
                                session: session,
                                onClose: { launch = nil })
        }
    }
}

/// A stacked label + single-line text field, styled for auto-content entry.
private struct LabeledField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
