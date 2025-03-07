/// For a comprehensive overview of this file and its relationships with other components,
/// see Sources/HTMLSoups/Documentation/ProjectOverview.swift
///
/// This file implements an intelligent selector learning system for HTMLSoups that
/// automatically learns and adapts CSS selectors based on success rates and patterns
/// found in web content. It handles dynamic content detection and provides a robust
/// mechanism for storing and retrieving learned patterns.
///
/// Key features:
/// - Automatic selector learning and adaptation
/// - Dynamic content detection
/// - Pattern storage and retrieval
/// - Confidence scoring system
/// - Domain-specific pattern learning
///
/// This system is used by:
/// - AdaptiveParser.swift: For learning and applying selectors
/// - HTMLParser.swift: For content extraction
/// - SelectorStorage.swift: For persisting learned patterns
///
/// Dependencies:
/// - LearningStorage.swift: For storing learned patterns
/// - SwiftSoup: For HTML parsing and selector operations

import Foundation
import SwiftSoup

/// Represents the learning data for selectors
public struct LearningData: Codable {
    public var domainPatterns: [String: [String: [String]]]  // domain -> contentType -> [selector]
    public var lastUpdated: Date
    public var successfulDomains: [String: [String]]  // selector -> domains
    public var selectorScores: [String: Double]  // selector -> confidence

    public init() {
        self.domainPatterns = [:]
        self.lastUpdated = Date()
        self.successfulDomains = [:]
        self.selectorScores = [:]
    }

    private enum CodingKeys: String, CodingKey {
        case domainPatterns
        case lastUpdated
        case successfulDomains
        case selectorScores
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.domainPatterns = try container.decode(
            [String: [String: [String]]].self, forKey: .domainPatterns)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.successfulDomains = try container.decode(
            [String: [String]].self, forKey: .successfulDomains)
        self.selectorScores = try container.decode([String: Double].self, forKey: .selectorScores)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(domainPatterns, forKey: .domainPatterns)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(successfulDomains, forKey: .successfulDomains)
        try container.encode(selectorScores, forKey: .selectorScores)
    }
}

/// A system for learning and adapting HTML selectors based on success rates
public class SelectorLearner {
    private var learningData: LearningData
    private let storage: LearningStorage

    // Common patterns for dynamic content containers
    private let dynamicContentPatterns = [
        "div[data-*]",  // Data attributes often indicate dynamic content
        "div[class*='content']",
        "div[class*='article']",
        "div[class*='story']",
        "div[class*='post']",
        "div[class*='entry']",
        "div[class*='main']",
        "div[id*='content']",
        "div[id*='article']",
        "div[id*='story']",
        "div[id*='post']",
        "div[id*='entry']",
        "div[id*='main']",
    ]

    // Common patterns for dynamic content loading indicators
    private let loadingIndicatorPatterns = [
        "div[class*='loading']",
        "div[class*='spinner']",
        "div[class*='progress']",
        "div[class*='wait']",
        "div[class*='pending']",
        "div[class*='ajax']",
        "div[class*='dynamic']",
    ]

    public init(storage: LearningStorage? = nil) async {
        self.learningData = LearningData()
        self.storage =
            storage
            ?? LocalLearningStorage(
                fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(
                    "temp_learning.json"))

        // Load existing learning data
        await withCheckedContinuation { continuation in
            self.storage.loadLearningData { [weak self] data, error in
                if let error = error {
                    print("Error loading learning data: \(error)")
                } else if let data = data {
                    self?.learningData = data
                }
                continuation.resume()
            }
        }
    }

    private func save() {
        learningData.lastUpdated = Date()
        storage.saveLearningData(learningData) { error in
            if let error = error {
                print("Error saving learning data: \(error)")
            }
        }
    }

    /// Learn selectors from a document with enhanced dynamic content detection
    public func learnSelectors(
        from document: Document, for contentType: String, domain: String,
        knownContent: String? = nil
    ) throws -> [String] {
        var selectors: [String] = []

        // First try domain-specific patterns
        if let domainPatterns = learningData.domainPatterns[domain]?[contentType] {
            selectors.append(contentsOf: domainPatterns)
        }

        // Then try known content if provided
        if let knownContent = knownContent {
            let elements = try document.getAllElements()
            for element in elements {
                if try element.text() == knownContent {
                    let selector = try element.cssSelector()
                    selectors.append(simplifySelector(selector))
                }
            }
        }

        // Find dynamic containers
        let containers = try findDynamicContainers(in: document)

        // Discover selectors from containers
        for container in containers {
            let containerSelectors = try discoverSelectorsFromContainer(
                container, contentType: contentType)
            selectors.append(contentsOf: containerSelectors)
        }

        // Try common patterns
        let commonPatterns = getCommonPatterns(for: contentType)
        selectors.append(contentsOf: commonPatterns)

        // Sort by confidence and specificity
        selectors.sort { compareSelectors($0, $1) }

        // Store learned selectors
        if !selectors.isEmpty {
            if learningData.domainPatterns[domain] == nil {
                learningData.domainPatterns[domain] = [:]
            }
            learningData.domainPatterns[domain]?[contentType] = selectors
            try save()
        }

        return selectors
    }

    private func findDynamicContainers(in document: Document) throws -> [Element] {
        var containers: [Element] = []

        // Look for loading indicators
        let loadingPatterns = [
            "div.loading",
            "div.spinner",
            "div.loading-spinner",
            "div.loading-indicator",
            "div.loading-overlay",
            "div.wait",
            "div[class*='loading']",
            "div[class*='spinner']",
        ]

        for pattern in loadingPatterns {
            let elements = try document.select(pattern)
            for element in elements {
                // Add the loading indicator itself
                containers.append(element)

                // Add its parent container if it exists
                if let parent = element.parent() {
                    containers.append(parent)
                }

                // Add nearby containers
                let nearby = findNearbyContainers(element)
                containers.append(contentsOf: nearby)
            }
        }

        // Look for dynamic content indicators
        let dynamicPatterns = [
            "div[data-article]",
            "div[data-content]",
            "div[class*='dynamic']",
            "div[class*='content']",
            "article",
            "main",
            "section",
        ]

        for pattern in dynamicPatterns {
            let elements = try document.select(pattern)
            containers.append(contentsOf: elements)
        }

        return containers
    }

    private func getCommonPatterns(for contentType: String) -> [String] {
        switch contentType {
        case "title":
            return [
                "h1",
                "h2",
                "h3",
                "h4",
                "h5",
                "h6",
                "[class*='title']",
                "[class*='headline']",
            ]
        case "content":
            return [
                "p",
                "div[class*='content']",
                "div[class*='article']",
                "div[class*='post']",
                "div[class*='entry']",
            ]
        case "author":
            return [
                "span[class*='author'], div[class*='author'], a[class*='author']"
            ]
        case "date":
            return [
                "time, span[class*='date'], div[class*='date']"
            ]
        default:
            return []
        }
    }

    private func findNearbyContainers(_ element: Element) -> [Element] {
        var containers: [Element] = []

        // Get parent containers
        var current = element.parent()
        while let parent = current {
            if isContainer(parent) {
                containers.append(parent)
            }
            current = parent.parent()
        }

        // Get sibling containers
        let siblings = element.siblingElements()
        for sibling in siblings {
            if isContainer(sibling) {
                containers.append(sibling)
            }
        }

        return containers
    }

    private func isContainer(_ element: Element) -> Bool {
        let containerClasses = [
            "content",
            "article",
            "post",
            "entry",
            "dynamic",
            "main",
            "section",
        ]

        let className = try? element.className()
        return className.map { className in
            containerClasses.contains { className.contains($0) }
        } ?? false
    }

    private func discoverSelectorsFromContainer(_ container: Element, contentType: String) throws
        -> [String]
    {
        var selectors: [String] = []

        // Get container selector
        let containerSelector = try container.cssSelector()
        let simplifiedContainerSelector = simplifySelector(containerSelector)

        // Find elements within container based on content type
        switch contentType {
        case "title":
            let headings = try container.select("h1, h2, h3")
            for heading in headings {
                let selector = try heading.cssSelector()
                let simplifiedSelector = simplifySelector(selector)
                selectors.append(simplifiedSelector)
                selectors.append("\(simplifiedContainerSelector) \(simplifiedSelector)")
                // Also add a simpler container-based selector
                selectors.append("\(simplifiedContainerSelector) \(heading.tagName())")
            }
        case "content":
            let contentElements = try container.select(
                "p, div[class*='content'], div[class*='article'], div[class*='body']")
            for element in contentElements {
                let selector = try element.cssSelector()
                let simplifiedSelector = simplifySelector(selector)
                selectors.append(simplifiedSelector)
                selectors.append("\(simplifiedContainerSelector) \(simplifiedSelector)")
                // Also add a simpler container-based selector
                selectors.append("\(simplifiedContainerSelector) \(element.tagName())")
                // Add container-based selector with class
                if let className = try? element.className(), !className.isEmpty {
                    selectors.append("\(simplifiedContainerSelector) .\(className)")
                }
            }
        case "author":
            let authorElements = try container.select(
                "span[class*='author'], div[class*='author'], a[class*='author']")
            for element in authorElements {
                let selector = try element.cssSelector()
                let simplifiedSelector = simplifySelector(selector)
                selectors.append(simplifiedSelector)
                selectors.append("\(simplifiedContainerSelector) \(simplifiedSelector)")
                // Also add a simpler container-based selector
                selectors.append("\(simplifiedContainerSelector) \(element.tagName())")
            }
        case "date":
            let dateElements = try container.select("time, span[class*='date'], div[class*='date']")
            for element in dateElements {
                let selector = try element.cssSelector()
                let simplifiedSelector = simplifySelector(selector)
                selectors.append(simplifiedSelector)
                selectors.append("\(simplifiedContainerSelector) \(simplifiedSelector)")
                // Also add a simpler container-based selector
                selectors.append("\(simplifiedContainerSelector) \(element.tagName())")
            }
        default:
            break
        }

        return selectors
    }

    private func simplifySelector(_ selector: String) -> String {
        // Remove html > body prefix
        let withoutPrefix = selector.replacingOccurrences(of: "html > body > ", with: "")

        // Get the last part of the selector
        let parts = withoutPrefix.components(separatedBy: " > ")
        if let lastPart = parts.last {
            return lastPart
        }

        return withoutPrefix
    }

    private func compareSelectors(_ a: String, _ b: String) -> Bool {
        // Prioritize common patterns
        let commonPatterns = [
            "h1.headline",
            "h1.title",
            "div.content",
            "div.article-content",
            "span.author",
            "time.date",
        ]

        if commonPatterns.contains(a) && !commonPatterns.contains(b) {
            return true
        }
        if !commonPatterns.contains(a) && commonPatterns.contains(b) {
            return false
        }

        // Then compare by specificity
        let specificityA = calculateSpecificity(a)
        let specificityB = calculateSpecificity(b)

        if specificityA != specificityB {
            return specificityA > specificityB
        }

        // Finally, prefer shorter selectors
        return a.count < b.count
    }

    private func calculateSpecificity(_ selector: String) -> Int {
        var score = 0

        // ID selectors
        score += selector.components(separatedBy: "#").count - 1

        // Class selectors
        score += selector.components(separatedBy: ".").count - 1

        // Attribute selectors
        score += selector.components(separatedBy: "[").count - 1

        // Pseudo-classes
        score += selector.components(separatedBy: ":").count - 1

        // Element selectors
        score += selector.components(separatedBy: " ").count - 1

        // Penalize complex selectors
        if selector.contains(">") || selector.contains("+") || selector.contains("~") {
            score -= 2
        }

        return score
    }

    /// Discover potential selectors by analyzing the document structure
    public func discoverSelectors(
        from document: Document, for contentType: String, matching content: String
    ) throws -> Set<String> {
        var discoveredSelectors = Set<String>()
        let elementPatterns = [
            ("h1", 1.0),
            ("h2", 0.9),
            ("h3", 0.8),
            ("article", 1.0),
            ("div.article-content", 0.9),
            ("div.content", 0.8),
            ("p", 0.7),
        ]

        for (pattern, baseConfidence) in elementPatterns {
            let elements = try document.select(pattern)
            for element in elements {
                if let text = try? element.text(),
                    text.contains(content)
                {
                    // Build CSS selector
                    let tagName = element.tagName()
                    let id = element.id()
                    let className = try element.className()

                    // Build selectors from most to least specific
                    var selectors = [String]()

                    // Most specific: tag + class + id
                    if !id.isEmpty && !className.isEmpty {
                        selectors.append("\(tagName).\(className)#\(id)")
                    }

                    // Next: tag + class
                    if !className.isEmpty {
                        // Split class names and create a selector for each one
                        let classes = className.split(separator: " ")
                        for cls in classes {
                            selectors.append("\(tagName).\(cls)")
                        }
                    }

                    // Next: tag + id
                    if !id.isEmpty {
                        selectors.append("\(tagName)#\(id)")
                    }

                    // Least specific: just tag
                    selectors.append(tagName)

                    // Add selectors to discovered set
                    discoveredSelectors.formUnion(selectors)

                    // Initialize selector scores
                    for selector in selectors {
                        if learningData.selectorScores[selector] == nil {
                            learningData.selectorScores[selector] = baseConfidence
                        }
                    }
                }
            }
        }

        return discoveredSelectors
    }

    /// Report the success or failure of a selector
    /// - Parameters:
    ///   - selector: The selector that was used
    ///   - contentType: The type of content that was being extracted
    ///   - domain: The domain of the content
    ///   - success: Whether the selector successfully found the right content
    public func reportResult(selector: String, contentType: String, domain: String, success: Bool) {
        // Update selector score
        if learningData.selectorScores[selector] == nil {
            learningData.selectorScores[selector] = 1.0
        }

        if success {
            learningData.selectorScores[selector]! += 0.2

            // Track successful domains
            if learningData.successfulDomains[selector] == nil {
                learningData.successfulDomains[selector] = []
            }
            if !learningData.successfulDomains[selector]!.contains(domain) {
                learningData.successfulDomains[selector]!.append(domain)
            }

            // Add to domain patterns
            if learningData.domainPatterns[domain] == nil {
                learningData.domainPatterns[domain] = [:]
            }
            if learningData.domainPatterns[domain]![contentType] == nil {
                learningData.domainPatterns[domain]![contentType] = []
            }
            if !learningData.domainPatterns[domain]![contentType]!.contains(selector) {
                learningData.domainPatterns[domain]![contentType]!.append(selector)
            }
        } else {
            learningData.selectorScores[selector]! -= 0.1
        }

        save()
    }

    /// Get learned selectors for a content type and domain
    /// - Parameters:
    ///   - contentType: The type of content to get selectors for
    ///   - domain: The domain of the content
    /// - Returns: Array of selectors ordered by confidence
    public func getLearnedSelectors(for contentType: String, domain: String? = nil) -> [String] {
        var allSelectors = Set<String>()

        // Add domain-specific patterns if available
        if let domain = domain,
            let domainPatterns = learningData.domainPatterns[domain]?[contentType]
        {
            allSelectors.formUnion(domainPatterns)
        }

        // Sort by confidence and prioritize common patterns
        return Array(allSelectors).sorted { s1, s2 in
            let c1 = learningData.selectorScores[s1] ?? 0
            let c2 = learningData.selectorScores[s2] ?? 0

            // If one selector is a common pattern, prioritize it
            let isCommon1 = (learningData.successfulDomains[s1]?.count ?? 0) > 1
            let isCommon2 = (learningData.successfulDomains[s2]?.count ?? 0) > 1

            if isCommon1 && !isCommon2 {
                return true
            } else if !isCommon1 && isCommon2 {
                return false
            }

            return c1 > c2
        }
    }

    /// Get selector confidence
    /// - Parameters:
    ///   - selector: The selector to get confidence for
    /// - Returns: The confidence of the selector
    public func getSelectorConfidence(_ selector: String) -> Double {
        return learningData.selectorScores[selector] ?? 0
    }

    /// Check if a selector is commonly successful across domains
    private func isCommonPattern(selector: String, contentType: String) -> Bool {
        var successfulDomains = Set<String>()

        // Check domain patterns
        for (domain, patterns) in learningData.domainPatterns {
            if let contentPatterns = patterns[contentType],
                contentPatterns.contains(selector)
            {
                successfulDomains.insert(domain)
            }
        }

        // Consider a pattern common if it's successful in at least 2 domains
        // and it's a specific selector (contains class or id)
        return successfulDomains.count >= 2 && (selector.contains(".") || selector.contains("#"))
    }
}
