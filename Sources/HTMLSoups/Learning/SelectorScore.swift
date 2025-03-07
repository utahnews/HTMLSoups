import Foundation

/// Represents a selector's effectiveness score
public struct SelectorScore: Codable {
    public let selector: String
    public let confidence: Double
    public let successCount: Int
    public let totalAttempts: Int
    public let lastUsed: Date
    
    public var successRate: Double {
        return Double(successCount) / Double(totalAttempts)
    }
    
    public init(selector: String, confidence: Double = 1.0, successCount: Int = 0, totalAttempts: Int = 0) {
        self.selector = selector
        self.confidence = confidence
        self.successCount = successCount
        self.totalAttempts = totalAttempts
        self.lastUsed = Date()
    }
    
    public func updated(success: Bool) -> SelectorScore {
        return SelectorScore(
            selector: selector,
            confidence: confidence * (success ? 1.1 : 0.9),  // Adjust confidence based on success
            successCount: successCount + (success ? 1 : 0),
            totalAttempts: totalAttempts + 1
        )
    }
} 