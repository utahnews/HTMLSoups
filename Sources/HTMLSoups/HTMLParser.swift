/// This file implements the core HTML parsing functionality for HTMLSoups.
/// It provides a robust parser that can handle both static and dynamic content,
/// with support for retry mechanisms and content merging.
///
/// Key features:
/// - Static and dynamic content parsing
/// - Retry mechanism for failed requests
/// - Dynamic content merging
/// - CSS selector-based content extraction
/// - Error handling and recovery
///
/// This parser is used by:
/// - AdaptiveParser.swift: For parsing HTML content
/// - SelectorLearner.swift: For learning patterns
/// - Article.swift: For content extraction
///
/// Dependencies:
/// - NetworkManager.swift: For fetching content
/// - SwiftSoup: For HTML parsing
///
/// The parser implements best practices for handling modern web content,
/// including dynamic loading and content updates.

import Foundation
import SwiftSoup

public class HTMLParser {
    private let networkManager: NetworkManager

    public init() {
        self.networkManager = NetworkManager.shared
    }

    /// Fetches and parses HTML content from a URL with retry mechanism
    /// - Parameters:
    ///   - url: The URL to fetch HTML from
    ///   - parser: A closure that receives the parsed Document and returns the desired content
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - retryDelay: Delay in seconds between retries (default: 1.0)
    /// - Returns: The parsed content
    public func parse<T: HTMLContent>(
        url: URL,
        parser: @escaping (Document) throws -> T,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                // Fetch initial HTML content
                let html = try await networkManager.fetchHTML(from: url)

                // Parse initial HTML into a Document
                var document = try SwiftSoup.parse(html, url.absoluteString)

                // Try to fetch dynamic content
                if let dynamicContent = try await networkManager.fetchDynamicContent(from: url),
                    let dynamicDoc = try? SwiftSoup.parse(dynamicContent)
                {
                    // Merge dynamic content with initial document
                    try mergeDynamicContent(into: &document, from: dynamicDoc)
                }

                // Apply the custom parser
                return try parser(document)
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }

        throw lastError
            ?? HTMLParsingError.parsingError(
                NSError(
                    domain: "HTMLSoups", code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Failed to parse content after \(maxRetries) attempts"
                    ]))
    }

    /// Merges dynamic content into the main document
    /// - Parameters:
    ///   - document: The main document to update
    ///   - dynamicDoc: The document containing dynamic content
    private func mergeDynamicContent(into document: inout Document, from dynamicDoc: Document)
        throws
    {
        // Common content container selectors
        let containerSelectors = [
            "article",
            ".article-content",
            ".story-content",
            "main",
            "#main-content",
        ]

        // Try to find and merge content from each potential container
        for selector in containerSelectors {
            if let dynamicContent = try? dynamicDoc.select(selector).first(),
                let mainContent = try? document.select(selector).first()
            {
                try mainContent.html(dynamicContent.html())
                break
            }
        }
    }

    /// Helper method to extract text content using a CSS selector
    /// - Parameters:
    ///   - document: The parsed HTML document
    ///   - selector: CSS selector to find the element
    /// - Returns: Text content of the first matching element
    public func extractText(from document: Document, selector: String) throws -> String {
        guard let element = try document.select(selector).first() else {
            throw HTMLParsingError.elementNotFound(selector)
        }
        return try element.text()
    }

    /// Helper method to extract an attribute value using a CSS selector
    /// - Parameters:
    ///   - document: The parsed HTML document
    ///   - selector: CSS selector to find the element
    ///   - attribute: Name of the attribute to extract
    /// - Returns: Value of the specified attribute from the first matching element
    public func extractAttribute(from document: Document, selector: String, attribute: String)
        throws -> String
    {
        guard let element = try document.select(selector).first() else {
            throw HTMLParsingError.elementNotFound(selector)
        }
        return try element.attr(attribute)
    }

    /// Helper method to extract multiple text elements using a CSS selector
    /// - Parameters:
    ///   - document: The parsed HTML document
    ///   - selector: CSS selector to find the elements
    /// - Returns: Array of text content from all matching elements
    public func extractTextArray(from document: Document, selector: String) throws -> [String] {
        let elements = try document.select(selector)
        return try elements.map { try $0.text() }
    }
}
