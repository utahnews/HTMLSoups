import Foundation

/// For a comprehensive overview of this file and its relationships with other components,
/// see Sources/HTMLSoups/Documentation/ProjectOverview.swift
///
/// This file implements persistent storage for learned selector patterns in HTMLSoups.
/// It provides functionality for saving and loading selector patterns for different
/// domains, allowing the system to maintain learned patterns between sessions.
///
/// Key features:
/// - Persistent storage of selector patterns
/// - Domain-specific pattern management
/// - JSON-based storage format
/// - File system-based persistence
///
/// This storage system is used by:
/// - SelectorLearner.swift: For saving and loading learned patterns
/// - AdaptiveParser.swift: For retrieving domain-specific patterns
/// - LearningStorage.swift: As a concrete implementation
///
/// The storage system uses the application support directory for
/// persistent storage of learned patterns.

/// Manages persistence of learned selector patterns
public class SelectorStorage {
    private let fileManager = FileManager.default
    private let storageURL: URL

    public init() throws {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        storageURL = appSupport.appendingPathComponent("HTMLSoups/learned_patterns")
        try fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)
    }

    /// Saves learned patterns for a domain
    public func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String) throws
    {
        let data = try JSONEncoder().encode(patterns)
        let fileURL = storageURL.appendingPathComponent("\(domain).json")
        try data.write(to: fileURL)
    }

    /// Loads learned patterns for a domain
    public func loadPatternsForDomain(_ domain: String) throws -> [String: [SelectorScore]] {
        let fileURL = storageURL.appendingPathComponent("\(domain).json")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([String: [SelectorScore]].self, from: data)
    }

    /// Lists all domains with learned patterns
    public func listLearnedDomains() throws -> [String] {
        let contents = try fileManager.contentsOfDirectory(
            at: storageURL,
            includingPropertiesForKeys: nil
        )
        return
            contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Removes learned patterns for a domain
    public func removePatternsForDomain(_ domain: String) throws {
        let fileURL = storageURL.appendingPathComponent("\(domain).json")
        try fileManager.removeItem(at: fileURL)
    }
}
