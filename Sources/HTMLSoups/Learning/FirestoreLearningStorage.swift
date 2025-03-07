import Foundation
import FirebaseFirestore

/// Error types for Firestore storage
public enum FirestoreStorageError: Error {
    case configurationError(String)
    case serializationError(String)
}

/// Manages persistence of learned selector patterns in Firestore
public class FirestoreLearningStorage: LearningStorage {
    private let db: Firestore
    private let collection = "learned_patterns"
    
    public init() throws {
        // Ensure Firebase is configured
        do {
            try FirebaseManager.shared.configure()
            self.db = Firestore.firestore()
        } catch let error as FirebaseError {
            throw FirestoreStorageError.configurationError(error.localizedDescription)
        } catch {
            throw FirestoreStorageError.configurationError("Firebase configuration failed: \(error.localizedDescription)")
        }
    }
    
    /// Firestore document structure
    struct FirestorePattern: Codable {
        var selectorScores: [String: [SelectorScore]]
        var domainPatterns: [String: [String: [String]]]
        var lastUpdated: Date
        var successfulDomains: [String: [String]]  // Convert Set to Array for Firestore
        
        init(from learningData: LearningData) {
            self.selectorScores = learningData.selectorScores
            self.domainPatterns = learningData.domainPatterns
            self.lastUpdated = learningData.lastUpdated
            // Convert Set to Array for Firestore storage
            self.successfulDomains = learningData.successfulDomains.mapValues { Array($0) }
        }
        
        func toLearningData() -> LearningData {
            var data = LearningData()
            data.selectorScores = self.selectorScores
            data.domainPatterns = self.domainPatterns
            data.lastUpdated = self.lastUpdated
            // Convert Array back to Set
            data.successfulDomains = self.successfulDomains.mapValues { Set($0) }
            return data
        }
    }
    
    /// Save learning data to Firestore
    /// - Parameters:
    ///   - learningData: The learning data to save
    ///   - completion: Completion handler with optional error
    public func saveLearningData(_ learningData: LearningData, completion: @escaping (Error?) -> Void) {
        let pattern = FirestorePattern(from: learningData)
        do {
            let data = try JSONEncoder().encode(pattern)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(NSError(domain: "FirestoreLearningStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"]))
                return
            }
            db.collection(collection).document("global").setData(dict) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    /// Load learning data from Firestore
    /// - Parameter completion: Completion handler with optional LearningData and error
    public func loadLearningData(completion: @escaping (LearningData?, Error?) -> Void) {
        db.collection(collection).document("global").getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(LearningData(), nil)  // Return empty data if no document exists
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let pattern = try JSONDecoder().decode(FirestorePattern.self, from: jsonData)
                completion(pattern.toLearningData(), nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    /// Save patterns for a specific domain
    /// - Parameters:
    ///   - patterns: The patterns to save
    ///   - domain: The domain to save patterns for
    ///   - completion: Completion handler with optional error
    public func savePatternsForDomain(_ patterns: [String: [SelectorScore]], domain: String, completion: @escaping (Error?) -> Void) {
        do {
            let data = try JSONEncoder().encode(patterns)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(NSError(domain: "FirestoreLearningStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"]))
                return
            }
            db.collection(collection).document(domain).setData(dict) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    /// Load patterns for a specific domain
    /// - Parameters:
    ///   - domain: The domain to load patterns for
    ///   - completion: Completion handler with optional patterns and error
    public func loadPatternsForDomain(_ domain: String, completion: @escaping ([String: [SelectorScore]]?, Error?) -> Void) {
        db.collection(collection).document(domain).getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion([:], nil)  // Return empty patterns if no document exists
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let patterns = try JSONDecoder().decode([String: [SelectorScore]].self, from: jsonData)
                completion(patterns, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    /// List all domains with learned patterns
    /// - Parameter completion: Completion handler with array of domain names and optional error
    public func listLearnedDomains(completion: @escaping ([String], Error?) -> Void) {
        db.collection(collection).getDocuments { (snapshot, error) in
            if let error = error {
                completion([], error)
                return
            }
            
            let domains = snapshot?.documents.map { $0.documentID } ?? []
            completion(domains.filter { $0 != "global" }, nil)
        }
    }
} 