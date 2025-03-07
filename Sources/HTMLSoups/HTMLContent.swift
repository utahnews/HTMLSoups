import Foundation

/// Protocol that all parsed HTML content models must conform to
public protocol HTMLContent: Codable {
    /// The source URL from which the content was parsed
    var sourceURL: URL { get }
}

/// Represents an error that occurred during HTML parsing
public enum HTMLParsingError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case invalidSelector(String)
    case elementNotFound(String)
}

/// A basic content model that can store key-value pairs of parsed data
public struct GenericHTMLContent: HTMLContent {
    public let sourceURL: URL
    public var data: [String: String]
    
    public init(sourceURL: URL, data: [String: String]) {
        self.sourceURL = sourceURL
        self.data = data
    }
} 