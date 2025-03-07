import Foundation
import FirebaseCore
import FirebaseFirestore

/// Manages Firebase configuration and initialization
public class FirebaseConfig {
    public static let shared = FirebaseConfig()
    
    private init() {}
    
    /// Configure and initialize Firebase
    public func configure() {
        let options = FirebaseOptions(
            googleAppID: "1:185254108563:web:f1917afa516eef0ba71c66",
            gcmSenderID: "185254108563"
        )
        options.apiKey = "AIzaSyBDJ_Vzkm7S3AelPoIB6lc7b-FSswJD3Xg"
        options.projectID = "utahnews-b3103"
        options.storageBucket = "utahnews-b3103.firebasestorage.app"
        
        // Initialize Firebase if it hasn't been initialized yet
        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
    }
} 