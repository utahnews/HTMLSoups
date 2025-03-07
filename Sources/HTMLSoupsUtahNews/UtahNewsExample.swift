import Foundation
import SwiftSoup
import HTMLSoups

/// Example configurations for different Utah news websites
public enum UtahNewsConfigs {
    /// Configuration for Deseret News articles
    public static func deseretNews() -> HTMLParser.NewsParserConfig {
        HTMLParser.NewsParserConfig(
            titleSelector: "h1.headline",
            contentSelector: "div.article-body",
            authorSelector: "div.author-name",
            dateSelector: "time.published-date",
            imageSelectors: ["div.article-hero img", "div.article-body img"],
            topicSelectors: ["div.article-tags a", "div.topics a"],
            organizationSelectors: ["div.article-body p strong"],
            locationSelectors: ["div.article-location", "div.article-body p em"]
        )
    }
    
    /// Configuration for Salt Lake Tribune articles
    public static func saltLakeTribune() -> HTMLParser.NewsParserConfig {
        HTMLParser.NewsParserConfig(
            titleSelector: "h1.article-title",
            contentSelector: "div.article-content",
            authorSelector: "div.byline a",
            dateSelector: "time.published",
            imageSelectors: ["figure.article-image img"],
            topicSelectors: ["div.article-topics a"],
            organizationSelectors: ["div.article-content p strong"],
            locationSelectors: ["div.article-dateline"]
        )
    }
    
    /// Configuration for KSL News articles
    public static func kslNews() -> HTMLParser.NewsParserConfig {
        HTMLParser.NewsParserConfig(
            titleSelector: "h1.headline",
            contentSelector: "div.article-content",
            authorSelector: "div.author-block a",
            dateSelector: "time.posted-date",
            imageSelectors: ["div.article-image img", "div.article-content img"],
            topicSelectors: ["div.tags a"],
            organizationSelectors: ["div.article-content p strong"],
            locationSelectors: ["div.location-tag"]
        )
    }
}

// Example usage:
/*
let parser = HTMLParser()

// Parse a Deseret News article
do {
    let url = URL(string: "https://www.deseret.com/example-article")!
    let config = UtahNewsConfigs.deseretNews()
    let mediaItem = try await parser.parseNewsContent(url: url, config: config)
    
    // Use the parsed MediaItem
    print("Title: \(mediaItem.title)")
    print("Author: \(mediaItem.author ?? "Unknown")")
    print("Published: \(mediaItem.publishedAt)")
    print("Topics: \(mediaItem.relationships.filter { $0.type == .topic }.map { $0.displayName })")
    print("Organizations: \(mediaItem.relationships.filter { $0.type == .organization }.map { $0.displayName })")
    print("Locations: \(mediaItem.relationships.filter { $0.type == .location }.map { $0.displayName })")
} catch {
    print("Error: \(error)")
}
*/ 