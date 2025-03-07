import Foundation
import HTMLSoups

extension UtahNewsConfigs {
    /// Configuration for Fox 13 News articles
    public static func fox13News() -> HTMLParser.NewsParserConfig {
        HTMLParser.NewsParserConfig(
            titleSelector: "h1",
            contentSelector: "article",
            authorSelector: "div.byline, span.author, .Article-author",
            dateSelector: "time, .Article-date, .posted-date",
            imageSelectors: ["img.article-image", ".Article-image img"],
            topicSelectors: [".category a", ".Article-tags a", ".tags a"],
            organizationSelectors: ["article p strong", ".Article-body strong", ".article-body strong"],
            locationSelectors: [".location", "p em:first-of-type", "dateline", "article p:first-of-type em"]
        )
    }
    
    /// Configuration for Lehi Free Press articles
    public static func lehiFreePress() -> HTMLParser.NewsParserConfig {
        HTMLParser.NewsParserConfig(
            titleSelector: "h1",
            contentSelector: ".entry-content, article",
            authorSelector: "span.meta-author a, .post-author, .byline, article .meta-author",
            dateSelector: "time.meta-date, span.meta-date, .post-date",
            imageSelectors: ["article img", ".entry-content img"],
            topicSelectors: [".category a", ".tags a", ".post-categories a"],
            organizationSelectors: [".entry-content p strong", "article p strong"],
            locationSelectors: [".entry-content p em:first-of-type", "article p em:first-of-type"]
        )
    }
} 