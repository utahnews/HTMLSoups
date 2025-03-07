import Foundation
import SwiftSoup
import UtahNewsData

/// A parser that can adapt its selectors based on learning from successful parses
public class AdaptiveParser {
    private let learner: SelectorLearner
    private var currentConfig: NewsParserConfig

    /// Initial configurations for known news sites
    private let initialConfigs: [String: NewsParserConfig] = [
        "kutv.com": NewsParserConfig(
            titleSelector: "h1.article-title",
            contentSelector: "div.article-content",
            authorSelector: "div.article-author",
            dateSelector: "div.article-date",
            imageSelectors: ["img.article-image"],
            topicSelectors: ["div.article-category"],
            organizationSelectors: ["div.article-source"],
            locationSelectors: ["div.article-location"]
        )
    ]

    public init() async {
        self.learner = await SelectorLearner()
        // Start with a generic configuration that works for most news sites
        self.currentConfig = NewsParserConfig(
            titleSelector: "h1",
            contentSelector: "article",
            authorSelector: "div.author, span.author",
            dateSelector: "time, div.date, span.date",
            imageSelectors: ["img.article-image", "img.featured-image"],
            topicSelectors: ["div.category", "span.category"],
            organizationSelectors: ["div.source", "span.source"],
            locationSelectors: ["div.location", "span.location"]
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
        // Check if we have a known configuration for this domain
        if let domain = url.host,
            let knownConfig = initialConfigs[domain]
        {
            currentConfig = knownConfig
        }

        let html = try await NetworkManager.shared.fetchHTML(from: url)
        let document = try SwiftSoup.parse(html)

        // Try to extract content using current configuration first
        do {
            return try extractContent(from: document, url: url)
        } catch {
            // If current configuration fails, try to learn new selectors
            guard let domain = url.host else {
                throw HTMLParsingError.invalidURL
            }

            let titleSelectors = try learner.learnSelectors(
                from: document, for: "title", domain: domain)
            let contentSelectors = try learner.learnSelectors(
                from: document, for: "content", domain: domain)
            let authorSelectors = try learner.learnSelectors(
                from: document, for: "author", domain: domain)
            let dateSelectors = try learner.learnSelectors(
                from: document, for: "date", domain: domain)
            let imageSelectors = try learner.learnSelectors(
                from: document, for: "image", domain: domain)
            let topicSelectors = try learner.learnSelectors(
                from: document, for: "topic", domain: domain)
            let orgSelectors = try learner.learnSelectors(
                from: document, for: "organization", domain: domain)
            let locationSelectors = try learner.learnSelectors(
                from: document, for: "location", domain: domain)

            // Update the current configuration with learned selectors
            if let titleSelector = titleSelectors.first {
                currentConfig.titleSelector = titleSelector
            }
            if let contentSelector = contentSelectors.first {
                currentConfig.contentSelector = contentSelector
            }
            if let authorSelector = authorSelectors.first {
                currentConfig.authorSelector = authorSelector
            }
            if let dateSelector = dateSelectors.first {
                currentConfig.dateSelector = dateSelector
            }
            if let imageSelector = imageSelectors.first {
                currentConfig.imageSelectors = [imageSelector]
            }
            if let topicSelector = topicSelectors.first {
                currentConfig.topicSelectors = [topicSelector]
            }
            if let orgSelector = orgSelectors.first {
                currentConfig.organizationSelectors = [orgSelector]
            }
            if let locationSelector = locationSelectors.first {
                currentConfig.locationSelectors = [locationSelector]
            }

            // Try extracting content again with updated configuration
            return try extractContent(from: document, url: url)
        }
    }

    /// Extract content from a document using the current configuration
    /// - Parameters:
    ///   - document: The parsed HTML document
    ///   - url: The source URL
    /// - Returns: The extracted article content
    private func extractContent(from document: Document, url: URL) throws -> ArticleContent {
        let title = try extractText(from: document, selector: currentConfig.titleSelector)
        let content = try extractText(from: document, selector: currentConfig.contentSelector)
        let author = currentConfig.authorSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }
        let publishDate = currentConfig.dateSelector.flatMap { selector in
            try? extractText(from: document, selector: selector)
        }

        // Extract image URLs
        var imageURLs: [URL] = []
        for selector in currentConfig.imageSelectors {
            if let elements = try? document.select(selector) {
                for element in elements {
                    if let src = try? element.attr("src"),
                        let imageURL = URL(string: src)
                    {
                        imageURLs.append(imageURL)
                    }
                }
            }
        }

        return ArticleContent(
            sourceURL: url,
            title: title,
            author: author,
            content: content,
            publishDate: publishDate,
            imageURLs: imageURLs
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
}
