import Foundation
@testable import HTMLSoups

/// Mock implementation of LearningStorage for testing
class MockLearningStorage: LearningStorage {
    private var learningData: LearningData?
    private var domainPatterns: [String: [String: [SelectorScore]]] = [:]
    
    func saveLearningData(_ learningData: LearningData, completion: @escaping (Error?) -> Void) {
        self.learningData = learningData
        completion(nil)
    }
    
    func loadLearningData(completion: @escaping (LearningData?, Error?) -> Void) {
        completion(learningData ?? LearningData(), nil)
    }
    
    func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String, completion: @escaping (Error?) -> Void) {
        domainPatterns[domain] = patterns
        completion(nil)
    }
    
    func loadPatternsForDomain(_ domain: String, completion: @escaping ([String: [SelectorScore]]?, Error?) -> Void) {
        completion(domainPatterns[domain] ?? [:], nil)
    }
    
    func listLearnedDomains(completion: @escaping ([String], Error?) -> Void) {
        completion(Array(domainPatterns.keys), nil)
    }
} 