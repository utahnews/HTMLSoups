import Foundation
import SwiftSoup
import FirebaseFirestore

/// Represents the learning data for selectors
public struct LearningData: Codable {
    public var selectorScores: [String: [SelectorScore]]  // contentType -> [SelectorScore]
    public var domainPatterns: [String: [String: [String]]]  // domain -> contentType -> [selector]
    public var lastUpdated: Date
    public var successfulDomains: [String: Set<String>]  // selector -> domains
    
    public init() {
        self.selectorScores = [:]
        self.domainPatterns = [:]
        self.lastUpdated = Date()
        self.successfulDomains = [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        case selectorScores
        case domainPatterns
        case lastUpdated
        case successfulDomains
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var scores: [String: [SelectorScore]] = [:]
        let scoresContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .selectorScores)
        for key in scoresContainer.allKeys {
            let scoresArray = try scoresContainer.decode([SelectorScore].self, forKey: key)
            scores[key.stringValue] = scoresArray
        }
        self.selectorScores = scores
        
        var patterns: [String: [String: [String]]] = [:]
        let patternsContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .domainPatterns)
        for key in patternsContainer.allKeys {
            let domainContainer = try patternsContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: key)
            var domainPatterns: [String: [String]] = [:]
            for contentKey in domainContainer.allKeys {
                domainPatterns[contentKey.stringValue] = try domainContainer.decode([String].self, forKey: contentKey)
            }
            patterns[key.stringValue] = domainPatterns
        }
        self.domainPatterns = patterns
        
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        
        var domains: [String: Set<String>] = [:]
        let domainsContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .successfulDomains)
        for key in domainsContainer.allKeys {
            domains[key.stringValue] = try domainsContainer.decode(Set<String>.self, forKey: key)
        }
        self.successfulDomains = domains
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var scoresContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .selectorScores)
        for (key, value) in selectorScores {
            try scoresContainer.encode(value, forKey: DynamicKey(stringValue: key))
        }
        
        var patternsContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .domainPatterns)
        for (domain, patterns) in domainPatterns {
            var domainContainer = patternsContainer.nestedContainer(keyedBy: DynamicKey.self, forKey: DynamicKey(stringValue: domain))
            for (contentType, selectors) in patterns {
                try domainContainer.encode(selectors, forKey: DynamicKey(stringValue: contentType))
            }
        }
        
        try container.encode(lastUpdated, forKey: .lastUpdated)
        
        var domainsContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .successfulDomains)
        for (key, value) in successfulDomains {
            try domainsContainer.encode(value, forKey: DynamicKey(stringValue: key))
        }
    }
    
    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }
}

/// A system for learning and adapting HTML selectors based on success rates
public class SelectorLearner {
    private var learningData: LearningData
    private let storage: LearningStorage
    
    public init(storage: LearningStorage? = nil) async {
        self.learningData = LearningData()
        
        if let providedStorage = storage {
            self.storage = providedStorage
        } else {
            // Try to use Firestore, fall back to temporary local storage if Firebase is not configured
            do {
                self.storage = try FirestoreLearningStorage()
            } catch {
                print("Warning: Firebase not configured, using temporary local storage")
                self.storage = LocalLearningStorage(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("temp_learning.json"))
            }
        }
        
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
    public func learnSelectors(from document: Document, for contentType: String, domain: String, knownContent: String? = nil) throws -> [String] {
        // First try domain-specific patterns
        if let domainPatterns = learningData.domainPatterns[domain]?[contentType] {
            for selector in domainPatterns {
                if let element = try? document.select(selector).first(),
                   let text = try? element.text(),
                   (knownContent == nil || text.contains(knownContent!)) {
                    reportResult(selector: selector, contentType: contentType, domain: domain, success: true)
                    let discovered = try discoverSelectors(from: document, for: contentType, matching: text)
                    return [selector] + discovered
                }
            }
        }
        
        // Try general patterns by confidence
        let generalPatterns = getLearnedSelectors(for: contentType)
        for selector in generalPatterns {
            if let element = try? document.select(selector).first(),
               let text = try? element.text(),
               (knownContent == nil || text.contains(knownContent!)) {
                reportResult(selector: selector, contentType: contentType, domain: domain, success: true)
                let discovered = try discoverSelectors(from: document, for: contentType, matching: text)
                return [selector] + discovered
            }
        }
        
        // If known content provided, discover new patterns
        if let knownContent = knownContent {
            return try discoverSelectors(from: document, for: contentType, matching: knownContent)
        }
        
        return []
    }
    
    /// Discover potential selectors by analyzing the document structure
    private func discoverSelectors(from document: Document, for contentType: String, matching content: String) throws -> [String] {
        var discovered: [String] = []
        
        // Common element patterns to try
        let elementPatterns: [(String, Double)] = [
            ("h1,h2,h3", 0.8),  // Headers for titles
            ("article,div,section", 0.6),  // Content containers
            ("span,p", 0.4),  // Text elements
            ("time", 0.9),  // Date elements
            ("a", 0.3)  // Links
        ]
        
        for (pattern, baseConfidence) in elementPatterns {
            let elements = try document.select(pattern)
            for element in elements {
                if try element.text().contains(content) {
                    // Build CSS selector
                    var selector = element.tagName()
                    let id = try element.id()
                    let className = try element.className()
                    
                    if !id.isEmpty {
                        selector += "#\(id)"
                    }
                    if !className.isEmpty {
                        selector += ".\(className.replacingOccurrences(of: " ", with: "."))"
                    }
                    
                    discovered.append(selector)
                    
                    // Add to learning data with initial confidence
                    let score = SelectorScore(selector: selector, confidence: baseConfidence)
                    if learningData.selectorScores[contentType] == nil {
                        learningData.selectorScores[contentType] = []
                    }
                    learningData.selectorScores[contentType]?.append(score)
                }
            }
        }
        
        save()
        return discovered
    }
    
    /// Report the success or failure of a selector
    /// - Parameters:
    ///   - selector: The selector that was used
    ///   - contentType: The type of content that was being extracted
    ///   - domain: The domain of the content
    ///   - success: Whether the selector successfully found the right content
    public func reportResult(selector: String, contentType: String, domain: String, success: Bool) {
        if learningData.selectorScores[contentType] == nil {
            learningData.selectorScores[contentType] = []
        }
        
        if let index = learningData.selectorScores[contentType]?.firstIndex(where: { $0.selector == selector }) {
            let updatedScore = learningData.selectorScores[contentType]![index].updated(success: success)
            learningData.selectorScores[contentType]![index] = updatedScore
            
            if success {
                // Track successful domains
                if learningData.successfulDomains[selector] == nil {
                    learningData.successfulDomains[selector] = []
                }
                learningData.successfulDomains[selector]?.insert(domain)
                
                // Add to domain patterns
                if learningData.domainPatterns[domain] == nil {
                    learningData.domainPatterns[domain] = [:]
                }
                if learningData.domainPatterns[domain]?[contentType] == nil {
                    learningData.domainPatterns[domain]?[contentType] = []
                }
                if !(learningData.domainPatterns[domain]?[contentType]?.contains(selector) ?? false) {
                    learningData.domainPatterns[domain]?[contentType]?.append(selector)
                }
            }
            
            save()
        }
    }
    
    /// Get learned selectors for a content type and domain
    /// - Parameters:
    ///   - contentType: The type of content to get selectors for
    ///   - domain: The domain of the content
    /// - Returns: Array of selectors ordered by confidence
    public func getLearnedSelectors(for contentType: String, domain: String? = nil) -> [String] {
        let scores = learningData.selectorScores[contentType] ?? []
        let domainScores = domain.flatMap { learningData.domainPatterns[$0]?[contentType] } ?? []
        
        // Combine and sort by confidence
        return (domainScores + scores.map { $0.selector })
            .sorted { s1, s2 in
                let score1 = scores.first { $0.selector == s1 }?.confidence ?? 0
                let score2 = scores.first { $0.selector == s2 }?.confidence ?? 0
                return score1 > score2
            }
    }
    
    /// Get selector confidence
    /// - Parameters:
    ///   - selector: The selector to get confidence for
    ///   - contentType: The type of content the selector is for
    ///   - domain: The domain of the content
    /// - Returns: The confidence of the selector
    public func getSelectorConfidence(_ selector: String, contentType: String, domain: String? = nil) -> Double {
        if let score = learningData.selectorScores[contentType]?.first(where: { $0.selector == selector }) {
            return score.confidence
        }
        return 0.0
    }
} 