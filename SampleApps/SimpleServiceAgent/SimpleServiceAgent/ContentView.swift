//
//  ContentView.swift
//  SimpleServiceAgent
//
//  The single configuration screen: three persisted text fields in a form,
//  with standalone Launch Voice / Launch Chat buttons just below it. The
//  buttons are enabled once all fields are filled in.
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
                    LabeledField(title: "Domain URL",
                                 prompt: "https://myorg.my.salesforce.com",
                                 text: $settings.domainURL,
                                 keyboard: .URL)
                    LabeledField(title: "Agent ID",
                                 prompt: "0Xxxx0000000000",
                                 text: $settings.agentID)
                    LabeledField(title: "SFAP URL",
                                 prompt: AppSettings.defaultSFAPURL,
                                 text: $settings.sfapURL,
                                 keyboard: .URL)
                    LabeledField(title: "Tenant ID (optional)",
                                 prompt: "Leave blank if not needed",
                                 text: $settings.tenantID)
                } header: {
                    Text("Guest Configuration")
                } footer: {
                    Text("Saved on this device and reused next time. Domain URL, Agent ID, and SFAP URL are required. The Domain URL hosts the guest bootstrap endpoint; SFAP URL defaults to \(AppSettings.defaultSFAPURL).")
                }

                launchButtons
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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

    private var launchButtons: some View {
        // A fixed-width stack keeps both buttons the same size and hugs its own
        // height. (A greedy GeometryReader here would force the list row to fill
        // all remaining vertical space, so we deliberately avoid one.)
        VStack(spacing: 12) {
            LaunchButton(title: "Launch Voice",
                         systemImage: "waveform") { launch = .voice }
            LaunchButton(title: "Launch Chat",
                         systemImage: "bubble.left.and.bubble.right") { launch = .chat }
        }
        .frame(width: 220)
        .disabled(!settings.isComplete)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

/// A fixed-width launch button on a neutral gray background. The icon and text
/// are colored explicitly by enabled state — blue icon / black text when
/// enabled, both gray when disabled — so they stay legible on the fill.
/// `maxWidth: .infinity` fills the width set by the surrounding stack so both
/// buttons match.
private struct LaunchButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .foregroundStyle(isEnabled ? Color.primary : .secondary)
            } icon: {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isEnabled ? Color.blue : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.gray)
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
