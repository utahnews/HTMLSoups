import Foundation

/// Manages a collection of User-Agent strings and provides rotation functionality
public class UserAgentManager {
    /// Collection of modern browser User-Agent strings
    private let userAgents: [String] = [
        // Chrome on macOS
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        // Firefox on macOS
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:123.0) Gecko/20100101 Firefox/123.0",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:122.0) Gecko/20100101 Firefox/122.0",
        // Safari on macOS
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15",
        // Edge on macOS
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.2365.92"
    ]
    
    /// Index for tracking the current User-Agent
    private var currentIndex: Int = 0
    
    /// Returns the next User-Agent string in the rotation
    public func nextUserAgent() -> String {
        let userAgent = userAgents[currentIndex]
        currentIndex = (currentIndex + 1) % userAgents.count
        return userAgent
    }
    
    /// Returns a random User-Agent string
    public func randomUserAgent() -> String {
        return userAgents.randomElement() ?? userAgents[0]
    }
    
    /// Singleton instance
    public static let shared = UserAgentManager()
    
    private init() {}
} 