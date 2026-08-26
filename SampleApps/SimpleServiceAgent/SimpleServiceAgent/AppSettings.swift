//
//  AppSettings.swift
//  SimpleServiceAgent
//
//  The three values that configure an Agentforce Service Agent. Each is
//  persisted to UserDefaults as it changes and restored on launch.
//

import Foundation
import Observation

@Observable
final class AppSettings {

    /// The Service API URL (SCRT2 messaging endpoint) for the deployment.
    var serviceAPIURL: String {
        didSet { defaults.set(serviceAPIURL, forKey: Keys.serviceAPIURL) }
    }

    /// The 15- or 18-character Salesforce Organization ID.
    var organizationID: String {
        didSet { defaults.set(organizationID, forKey: Keys.organizationID) }
    }

    /// The Embedded Service deployment developer name (`esDeveloperName`).
    var developerName: String {
        didSet { defaults.set(developerName, forKey: Keys.developerName) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.serviceAPIURL = defaults.string(forKey: Keys.serviceAPIURL) ?? ""
        self.organizationID = defaults.string(forKey: Keys.organizationID) ?? ""
        self.developerName = defaults.string(forKey: Keys.developerName) ?? ""
    }

    /// True once all three values contain non-whitespace content, at which
    /// point the Launch buttons become active.
    var isComplete: Bool {
        [serviceAPIURL, organizationID, developerName].allSatisfy { !$0.trimmed.isEmpty }
    }

    private enum Keys {
        static let serviceAPIURL = "SimpleServiceAgent.serviceAPIURL"
        static let organizationID = "SimpleServiceAgent.organizationID"
        static let developerName = "SimpleServiceAgent.developerName"
    }
}

extension String {
    /// Whitespace/newline-trimmed copy, used when validating and forwarding
    /// the configuration values to the SDK.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
