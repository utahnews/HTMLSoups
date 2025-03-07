import Foundation

/// Protocol defining the interface for learning data storage
public protocol LearningStorage {
    /// Save learning data
    /// - Parameters:
    ///   - learningData: The learning data to save
    ///   - completion: Completion handler with optional error
    func saveLearningData(_ learningData: LearningData, completion: @escaping (Error?) -> Void)
    
    /// Load learning data
    /// - Parameter completion: Completion handler with optional LearningData and error
    func loadLearningData(completion: @escaping (LearningData?, Error?) -> Void)
    
    /// Save patterns for a specific domain
    /// - Parameters:
    ///   - patterns: The patterns to save
    ///   - domain: The domain to save patterns for
    ///   - completion: Completion handler with optional error
    func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String, completion: @escaping (Error?) -> Void)
    
    /// Load patterns for a specific domain
    /// - Parameters:
    ///   - domain: The domain to load patterns for
    ///   - completion: Completion handler with optional patterns and error
    func loadPatternsForDomain(_ domain: String, completion: @escaping ([String: [SelectorScore]]?, Error?) -> Void)
    
    /// List all domains with learned patterns
    /// - Parameter completion: Completion handler with array of domain names and optional error
    func listLearnedDomains(completion: @escaping ([String], Error?) -> Void)
}

/// Local file-based implementation of LearningStorage for testing
public class LocalLearningStorage: LearningStorage {
    private let fileURL: URL
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    public func saveLearningData(_ learningData: LearningData, completion: @escaping (Error?) -> Void) {
        do {
            let data = try JSONEncoder().encode(learningData)
            try data.write(to: fileURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func loadLearningData(completion: @escaping (LearningData?, Error?) -> Void) {
        do {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                completion(LearningData(), nil)
                return
            }
            let data = try Data(contentsOf: fileURL)
            let learningData = try JSONDecoder().decode(LearningData.self, from: data)
            completion(learningData, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    public func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String, completion: @escaping (Error?) -> Void) {
        // For local storage, we'll save all patterns in the same file
        loadLearningData { [weak self] learningData, error in
            if let error = error {
                completion(error)
                return
            }
            
            var data = learningData ?? LearningData()
            if data.domainPatterns[domain] == nil {
                data.domainPatterns[domain] = [:]
            }
            
            // Convert patterns to domain patterns format
            for (contentType, scores) in patterns {
                data.domainPatterns[domain]?[contentType] = scores.map { $0.selector }
            }
            
            self?.saveLearningData(data, completion: completion)
        }
    }
    
    public func loadPatternsForDomain(_ domain: String, completion: @escaping ([String: [SelectorScore]]?, Error?) -> Void) {
        loadLearningData { learningData, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            let data = learningData ?? LearningData()
            let patterns = data.domainPatterns[domain]?.mapValues { selectors in
                selectors.map { SelectorScore(selector: $0) }
            }
            completion(patterns ?? [:], nil)
        }
    }
    
    public func listLearnedDomains(completion: @escaping ([String], Error?) -> Void) {
        loadLearningData { learningData, error in
            if let error = error {
                completion([], error)
                return
            }
            
            let data = learningData ?? LearningData()
            completion(Array(data.domainPatterns.keys), nil)
        }
    }
} 