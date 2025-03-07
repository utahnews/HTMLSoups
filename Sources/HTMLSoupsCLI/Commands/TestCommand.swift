import Foundation
import HTMLSoups

private func buildConfig(for url: URL) -> HTMLParser.NewsParserConfig {
    let host = url.host ?? ""
    
    if host.contains("fox13now.com") {
        return UtahNewsConfigs.fox13News()
    } else if host.contains("deseretnews.com") {
        return UtahNewsConfigs.deseretNews()
    } else if host.contains("sltrib.com") {
        return UtahNewsConfigs.saltLakeTribune()
    } else if host.contains("ksl.com") {
        return UtahNewsConfigs.kslNews()
    } else if host.contains("lehifreepress.com") {
        return UtahNewsConfigs.lehiFreePress()
    } else {
        // Default fallback configuration
        return HTMLParser.NewsParserConfig(
            titleSelector: "h1, .article-title, .entry-title, .headline",
            contentSelector: "article, .article-content, .entry-content, .article-body",
            authorSelector: ".author, .byline, .writer, .meta-author",
            dateSelector: "time, .published, .post-date",
            imageSelectors: ["img.article-image", ".featured-image img", "article img"],
            topicSelectors: [".tags a", ".categories a", ".topics a"],
            organizationSelectors: ["article p strong", ".article-body strong"],
            locationSelectors: [".location", "p em:first-of-type"]
        )
    }
} 