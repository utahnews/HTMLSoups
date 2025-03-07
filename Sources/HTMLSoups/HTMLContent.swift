/// This file defines the core protocols and types for HTML content parsing in HTMLSoups.
/// It serves as the foundation for all content models in the library, providing a common
/// interface that all parsed content must conform to. The file also defines error types
/// and a generic content model that can be used for basic parsing needs.
///
/// Key components:
/// - HTMLContent: Protocol that all content models must implement
/// - HTMLParsingError: Enumeration of possible parsing errors
/// - GenericHTMLContent: A flexible content model for basic parsing needs
///
/// This file is used by:
/// - Article.swift: Implements the HTMLContent protocol for article parsing
/// - ArticleContent.swift: Provides example implementation of HTMLContent
/// - AdaptiveParser.swift: Uses these types for parsing HTML content

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
    case parsingError(Error)
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
