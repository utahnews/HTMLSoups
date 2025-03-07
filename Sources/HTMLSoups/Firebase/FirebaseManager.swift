import Foundation
import FirebaseCore

/// Error types for Firebase configuration
public enum FirebaseError: Error {
    case configurationError(String)
}

/// Manages Firebase configuration
public class FirebaseManager {
    public static let shared = FirebaseManager()
    private var isConfigured = false
    
    private init() {}
    
    /// Configure Firebase with default options
    public func configure() throws {
        guard !isConfigured else { return }
        
        // Check if GoogleService-Info.plist exists in the bundle
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            throw FirebaseError.configurationError("GoogleService-Info.plist not found in bundle")
        }
        
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            throw FirebaseError.configurationError("Failed to load Firebase options from GoogleService-Info.plist")
        }
        
        FirebaseApp.configure(options: options)
        isConfigured = true
    }
} 