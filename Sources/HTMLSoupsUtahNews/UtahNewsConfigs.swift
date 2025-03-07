import Foundation
import HTMLSoups

/// Configuration presets for different Utah news sites
public enum UtahNewsConfigs {
        /// Configuration for Fox 13 News
        public static func fox13News() -> HTMLParser.NewsParserConfig {
                HTMLParser.NewsParserConfig(
                        titleSelector: "h1",
                        contentSelector: "article",
                        authorSelector: "div.byline, span.author, .Article-author",
                        dateSelector: "time, .Article-date, .posted-date",
                        imageSelectors: ["img.article-image", ".Article-image img"],
                        topicSelectors: [".category a", ".Article-tags a", ".tags a"],
                        organizationSelectors: [
                                "article p strong", ".Article-body strong", ".article-body strong",
                        ],
                        locationSelectors: [
                                ".location", "p em:first-of-type", "dateline",
                                "article p:first-of-type em",
                        ]
                )
        }

        /// Configuration for Deseret News
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

        /// Configuration for Salt Lake Tribune
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

        /// Configuration for KSL News
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

        /// Configuration for Lehi Free Press
        public static func lehiFreePress() -> HTMLParser.NewsParserConfig {
                HTMLParser.NewsParserConfig(
                        titleSelector: "h1",
                        contentSelector: ".entry-content, article",
                        authorSelector:
                                "span.meta-author a, .post-author, .byline, article .meta-author",
                        dateSelector: "time.meta-date, span.meta-date, .post-date",
                        imageSelectors: ["article img", ".entry-content img"],
                        topicSelectors: [".category a", ".tags a", ".post-categories a"],
                        organizationSelectors: [".entry-content p strong", "article p strong"],
                        locationSelectors: [
                                ".entry-content p em:first-of-type", "article p em:first-of-type",
                        ]
                )
        }
}
