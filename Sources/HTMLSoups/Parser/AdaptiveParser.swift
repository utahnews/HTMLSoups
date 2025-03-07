import Foundation
import SwiftSoup
import UtahNewsData

/// Error types for HTML parsing
public enum HTMLParsingError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(Error)
    case elementNotFound(String)
}

/// A parser that can adapt its selectors based on learning from successful parses
public class AdaptiveParser {
    private var learner: SelectorLearner
    private var currentConfig: NewsParserConfig
    
    public init() async {
        self.learner = SelectorLearner()
        self.currentConfig = NewsParserConfig(
            titleSelector: "h1",
            contentSelector: "article",
            authorSelector: nil,
            dateSelector: nil
        )
    }
    
    /// Parse an article from a URL and learn from the content
    /// - Parameter url: The URL to parse
    /// - Returns: The parsed article content
    public func parseAndLearn(from url: URL) async throws -> ArticleContent {
        let html = try await fetchHTML(from: url)
        let document = try SwiftSoup.parse(html)
        
        let title = try extractText(from: document, selector: currentConfig.titleSelector)
        let content = try extractText(from: document, selector: currentConfig.contentSelector)
        let author = try currentConfig.authorSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }
        let publishDate = try currentConfig.dateSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }
        
        let article = ArticleContent(
            sourceURL: url,
            title: title,
            content: content,
            author: author,
            publishDate: publishDate
        )
        
        // Learn from successful parse
        try await updateConfig(from: document)
        
        return article
    }
    
    /// Extract text from a document using a CSS selector
    /// - Parameters:
    ///   - document: The parsed HTML document
    ///   - selector: The CSS selector to use
    /// - Returns: The extracted text
    private func extractText(from document: Document, selector: String) throws -> String {
        guard let element = try document.select(selector).first() else {
            throw HTMLParsingError.elementNotFound(selector)
        }
        return try element.text()
    }
    
    /// Update the parser configuration based on learning from a document
    /// - Parameter document: The document to learn from
    private func updateConfig(from document: Document) async throws {
        let learnedSelectors = try await learner.learnSelectors(from: document)
        
        if let titleSelector = learnedSelectors.titleSelector {
            currentConfig.titleSelector = titleSelector
        }
        if let contentSelector = learnedSelectors.contentSelector {
            currentConfig.contentSelector = contentSelector
        }
        if let authorSelector = learnedSelectors.authorSelector {
            currentConfig.authorSelector = authorSelector
        }
        if let dateSelector = learnedSelectors.dateSelector {
            currentConfig.dateSelector = dateSelector
        }
    }
    
    /// Fetch HTML content from a URL
    /// - Parameter url: The URL to fetch from
    /// - Returns: The HTML content as a string
    private func fetchHTML(from url: URL) async throws -> String {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw HTMLParsingError.parsingError("Failed to decode HTML")
            }
            return html
        } catch {
            throw HTMLParsingError.networkError(error)
        }
    }
} 