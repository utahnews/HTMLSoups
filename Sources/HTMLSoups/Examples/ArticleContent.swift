import Foundation
import SwiftSoup

/// Example model for parsing article content
public struct ArticleContent: HTMLContent {
    public let sourceURL: URL
    public let title: String
    public let author: String?
    public let content: String
    public let publishDate: String?
    public let imageURLs: [URL]
    
    public init(sourceURL: URL, title: String, author: String?, content: String, publishDate: String?, imageURLs: [URL]) {
        self.sourceURL = sourceURL
        self.title = title
        self.author = author
        self.content = content
        self.publishDate = publishDate
        self.imageURLs = imageURLs
    }
}

/// Example parser configuration for different website structures
public struct ArticleParserConfig {
    let titleSelector: String
    let authorSelector: String?
    let contentSelector: String
    let dateSelector: String?
    let imageSelector: String
    
    public init(
        titleSelector: String,
        authorSelector: String? = nil,
        contentSelector: String,
        dateSelector: String? = nil,
        imageSelector: String
    ) {
        self.titleSelector = titleSelector
        self.authorSelector = authorSelector
        self.contentSelector = contentSelector
        self.dateSelector = dateSelector
        self.imageSelector = imageSelector
    }
}

extension HTMLParser {
    /// Parses article content using the provided configuration
    /// - Parameters:
    ///   - url: The URL of the article
    ///   - config: Configuration for parsing different elements
    /// - Returns: Parsed ArticleContent
    public func parseArticle(url: URL, config: ArticleParserConfig) async throws -> ArticleContent {
        try await parse(url: url) { document in
            let title = try self.extractText(from: document, selector: config.titleSelector)
            let content = try self.extractText(from: document, selector: config.contentSelector)
            
            let author = try config.authorSelector.flatMap { selector in
                try? self.extractText(from: document, selector: selector)
            }
            
            let publishDate = try config.dateSelector.flatMap { selector in
                try? self.extractText(from: document, selector: selector)
            }
            
            let imageElements = try document.select(config.imageSelector)
            let imageURLs = try imageElements.compactMap { element in
                let urlString = try element.attr("src")
                return URL(string: urlString)
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
    }
} 