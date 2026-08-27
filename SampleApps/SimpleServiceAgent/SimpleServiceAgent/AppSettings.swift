//
//  AppSettings.swift
//  SimpleServiceAgent
//
//  The values that configure a guest-authenticated Agentforce session. Each is
//  persisted to UserDefaults as it changes and restored on launch.
//

import Foundation
import Observation

@Observable
final class AppSettings {

    /// The org's My Domain URL (e.g. `https://myorg.my.salesforce.com`). It
    /// hosts the `/agentforce/bootstrap` guest endpoint that mints the access
    /// token, and is passed to the SDK as both the guest credential URL and the
    /// `forceConfigEndpoint`. Required.
    var domainURL: String {
        didSet { defaults.set(domainURL, forKey: Keys.domainURL) }
    }

    /// The target Agent ID. Passed as the `agentid` query parameter and used to
    /// start the conversation. Required.
    var agentID: String {
        didSet { defaults.set(agentID, forKey: Keys.agentID) }
    }

    /// The SFAP (Salesforce Agent Platform) base URL where API and voice calls
    /// go. Defaults to `https://api.salesforce.com`. Required.
    var sfapURL: String {
        didSet { defaults.set(sfapURL, forKey: Keys.sfapURL) }
    }

    /// Optional tenant identifier for the connection. Leave blank if not needed.
    var tenantID: String {
        didSet { defaults.set(tenantID, forKey: Keys.tenantID) }
    }

    private let defaults: UserDefaults

    /// The default SFAP endpoint used when the user has not entered one.
    static let defaultSFAPURL = "https://api.salesforce.com"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.domainURL = defaults.string(forKey: Keys.domainURL) ?? ""
        self.agentID = defaults.string(forKey: Keys.agentID) ?? ""
        // Seed the SFAP URL with the public default when nothing was saved yet
        // (property observers don't run during init), so it is populated on
        // first launch without waiting for an edit.
        let savedSFAP = defaults.string(forKey: Keys.sfapURL) ?? ""
        self.sfapURL = savedSFAP.isEmpty ? Self.defaultSFAPURL : savedSFAP
        self.tenantID = defaults.string(forKey: Keys.tenantID) ?? ""
    }

    /// True once the required values contain non-whitespace content, at which
    /// point the Launch buttons become active. (`tenantID` is optional and does
    /// not gate the buttons.)
    var isComplete: Bool {
        [domainURL, agentID, sfapURL].allSatisfy { !$0.trimmed.isEmpty }
    }

    private enum Keys {
        static let domainURL = "SimpleServiceAgent.domainURL"
        static let agentID = "SimpleServiceAgent.agentID"
        static let sfapURL = "SimpleServiceAgent.sfapURL"
        static let tenantID = "SimpleServiceAgent.tenantID"
    }
}

extension String {
    /// Whitespace/newline-trimmed copy, used when validating and forwarding
    /// the configuration values to the SDK.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
