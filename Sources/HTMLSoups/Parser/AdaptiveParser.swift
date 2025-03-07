import Foundation
import SwiftSoup
import UtahNewsData

/// A parser that can adapt its selectors based on learning from successful parses
public class AdaptiveParser {
    private let learner: SelectorLearner
    private var currentConfig: NewsParserConfig
    
    public init() async {
        self.learner = await SelectorLearner()
        self.currentConfig = NewsParserConfig(
            titleSelector: "h1",
            contentSelector: "article",
            authorSelector: nil,
            dateSelector: nil,
            imageSelectors: [],
            topicSelectors: [],
            organizationSelectors: [],
            locationSelectors: []
        )
    }
    
    /// Get the current parser configuration
    /// - Returns: The current NewsParserConfig
    public func getCurrentConfig() -> NewsParserConfig {
        return currentConfig
    }
    
    /// Parse an article from a URL and learn from the content
    /// - Parameter url: The URL to parse
    /// - Returns: The parsed article content
    public func parseAndLearn(_ url: URL) async throws -> ArticleContent {
        let html = try await NetworkManager.shared.fetchHTML(from: url)
        let document = try SwiftSoup.parse(html)
        
        let title = try extractText(from: document, selector: currentConfig.titleSelector)
        let content = try extractText(from: document, selector: currentConfig.contentSelector)
        let author = currentConfig.authorSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }
        let publishDate = currentConfig.dateSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }
        
        try await updateConfig(from: document, url: url)
        
        return ArticleContent(
            sourceURL: url,
            title: title,
            author: author,
            content: content,
            publishDate: publishDate,
            imageURLs: []
        )
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
    private func updateConfig(from document: Document, url: URL) async throws {
        let domain = url.host ?? ""
        let learnedSelectors = try learner.learnSelectors(from: document, for: "title", domain: domain)
        
        if !learnedSelectors.isEmpty {
            currentConfig.titleSelector = learnedSelectors[0]
        }
    }
} 