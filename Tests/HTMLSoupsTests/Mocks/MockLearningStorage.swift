import Foundation
@testable import HTMLSoups

/// Mock implementation of LearningStorage for testing
class MockLearningStorage: LearningStorage {
    private var learningData: LearningData = LearningData()
    
    func saveLearningData(_ data: LearningData, completion: @escaping (Error?) -> Void) {
        self.learningData = data
        completion(nil)
    }
    
    func loadLearningData(completion: @escaping (LearningData?, Error?) -> Void) {
        completion(learningData, nil)
    }
    
    func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String, completion: @escaping (Error?) -> Void) {
        // Convert SelectorScore array to string array
        var stringPatterns: [String: [String]] = [:]
        for (contentType, scores) in patterns {
            stringPatterns[contentType] = scores.map { $0.selector }
        }
        learningData.domainPatterns[domain] = stringPatterns
        completion(nil)
    }
    
    func loadPatternsForDomain(_ domain: String, completion: @escaping ([String: [SelectorScore]]?, Error?) -> Void) {
        // Convert string array to SelectorScore array
        if let patterns = learningData.domainPatterns[domain] {
            var scorePatterns: [String: [SelectorScore]] = [:]
            for (contentType, selectors) in patterns {
                scorePatterns[contentType] = selectors.map { SelectorScore(selector: $0, confidence: 1.0) }
            }
            completion(scorePatterns, nil)
        } else {
            completion(nil, nil)
        }
    }
    
    func listLearnedDomains(completion: @escaping ([String], Error?) -> Void) {
        completion(Array(learningData.domainPatterns.keys), nil)
    }
} 