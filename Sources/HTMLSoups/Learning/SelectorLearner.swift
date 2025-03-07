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
        
        self.domainPatterns = try container.decode([String: [String: [String]]].self, forKey: .domainPatterns)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.successfulDomains = try container.decode([String: [String]].self, forKey: .successfulDomains)
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
    
    public init(storage: LearningStorage? = nil) async {
        self.learningData = LearningData()
        self.storage = storage ?? LocalLearningStorage(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("temp_learning.json"))
        
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
    
    /// Learn selectors from a document
    /// - Parameters:
    ///   - document: The HTML document to learn from
    ///   - contentType: The type of content to find selectors for
    ///   - domain: The domain of the content
    ///   - knownContent: Optional known content for validation
    /// - Returns: Array of selectors ordered by confidence
    public func learnSelectors(from document: Document, for contentType: String, domain: String? = nil, knownContent: String? = nil) throws -> [String] {
        var discoveredSelectors = Set<String>()
        var prioritizedSelectors = [String]()
        
        // First try domain-specific patterns
        if let domain = domain,
           let domainPatterns = learningData.domainPatterns[domain]?[contentType] {
            for selector in domainPatterns {
                if let element = try? document.select(selector).first() {
                    if let knownContent = knownContent {
                        if let text = try? element.text(),
                           text.contains(knownContent) {
                            discoveredSelectors.insert(selector)
                            if learningData.successfulDomains[selector] == nil {
                                learningData.successfulDomains[selector] = []
                            }
                            if !learningData.successfulDomains[selector]!.contains(domain) {
                                learningData.successfulDomains[selector]!.append(domain)
                            }
                            // Initialize or update selector score
                            if learningData.selectorScores[selector] == nil {
                                learningData.selectorScores[selector] = 1.0
                            } else {
                                learningData.selectorScores[selector]! += 0.2
                            }
                        }
                    } else {
                        // If no known content, consider the selector valid if it finds an element
                        discoveredSelectors.insert(selector)
                        if learningData.successfulDomains[selector] == nil {
                            learningData.successfulDomains[selector] = []
                        }
                        if !learningData.successfulDomains[selector]!.contains(domain) {
                            learningData.successfulDomains[selector]!.append(domain)
                        }
                        // Initialize or update selector score
                        if learningData.selectorScores[selector] == nil {
                            learningData.selectorScores[selector] = 1.0
                        } else {
                            learningData.selectorScores[selector]! += 0.2
                        }
                    }
                }
            }
        }
        
        // Then try general patterns by confidence
        let generalPatterns = learningData.selectorScores.keys.sorted { s1, s2 in
            let c1 = learningData.selectorScores[s1] ?? 0
            let c2 = learningData.selectorScores[s2] ?? 0
            return c1 > c2
        }
        
        for selector in generalPatterns {
            if let element = try? document.select(selector).first() {
                if let knownContent = knownContent {
                    if let text = try? element.text(),
                       text.contains(knownContent) {
                        discoveredSelectors.insert(selector)
                        // Update selector score
                        learningData.selectorScores[selector]! += 0.2
                    }
                } else {
                    // If no known content, consider the selector valid if it finds an element
                    discoveredSelectors.insert(selector)
                    // Update selector score
                    learningData.selectorScores[selector]! += 0.2
                }
            }
        }
        
        // If we have known content, discover new patterns
        if let knownContent = knownContent {
            let newSelectors = try discoverSelectors(from: document, for: contentType, matching: knownContent)
            discoveredSelectors.formUnion(newSelectors)
            
            // Add discovered selectors to domain patterns
            if let domain = domain {
                if learningData.domainPatterns[domain] == nil {
                    learningData.domainPatterns[domain] = [:]
                }
                if learningData.domainPatterns[domain]![contentType] == nil {
                    learningData.domainPatterns[domain]![contentType] = []
                }
                for selector in newSelectors {
                    if !learningData.domainPatterns[domain]![contentType]!.contains(selector) {
                        learningData.domainPatterns[domain]![contentType]!.append(selector)
                    }
                    
                    // Initialize selector score
                    if learningData.selectorScores[selector] == nil {
                        learningData.selectorScores[selector] = 1.0
                    }
                }
            }
        }
        
        // Sort by confidence and prioritize common patterns
        prioritizedSelectors = Array(discoveredSelectors).sorted { s1, s2 in
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
            
            // If both are common or both are not common, use confidence
            // For common patterns, give them a significant boost
            if isCommon1 && isCommon2 {
                let domains1 = learningData.successfulDomains[s1]?.count ?? 0
                let domains2 = learningData.successfulDomains[s2]?.count ?? 0
                if domains1 != domains2 {
                    return domains1 > domains2
                }
            }
            
            return c1 > c2
        }
        
        save()
        return prioritizedSelectors
    }
    
    /// Discover potential selectors by analyzing the document structure
    public func discoverSelectors(from document: Document, for contentType: String, matching content: String) throws -> Set<String> {
        var discoveredSelectors = Set<String>()
        let elementPatterns = [
            ("h1", 1.0),
            ("h2", 0.9),
            ("h3", 0.8),
            ("article", 1.0),
            ("div.article-content", 0.9),
            ("div.content", 0.8),
            ("p", 0.7)
        ]
        
        for (pattern, baseConfidence) in elementPatterns {
            let elements = try document.select(pattern)
            for element in elements {
                if let text = try? element.text(),
                   text.contains(content) {
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
           let domainPatterns = learningData.domainPatterns[domain]?[contentType] {
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
               contentPatterns.contains(selector) {
                successfulDomains.insert(domain)
            }
        }
        
        // Consider a pattern common if it's successful in at least 2 domains
        // and it's a specific selector (contains class or id)
        return successfulDomains.count >= 2 && (selector.contains(".") || selector.contains("#"))
    }
} 