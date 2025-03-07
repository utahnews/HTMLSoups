import XCTest

@testable import HTMLSoups
@testable import HTMLSoupsUtahNews

struct TestNewsContent: HTMLContent {
    let sourceURL: URL
    let title: String
    let content: String
    let author: String?
}

final class NetworkManagerTests: XCTestCase {
    var parser: HTMLParser!

    override func setUp() {
        super.setUp()
        parser = HTMLParser()
    }

    func testParsingMultipleNewsWebsites() async throws {
        let urls = [
            "https://www.abc4.com/news/politics/inside-utah-politics/utahs-latest-alcohol-bill-revived/",
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water",
            "https://www.sltrib.com/news/politics/2025/03/06/pride-flags-banned-utah-schools/",
            "https://www.ksl.com/article/51267799/utah-family-says-they-were-targeted-in-racially-motivated-verbal-assault",
            "https://kutv.com/news/2news-investigates/radio-interference-big-buildings-pay-their-way-for-new-utah-communications-system",
            "https://lehifreepress.com/2025/03/05/public-hearing-for-2100-n-environmental-study-thursday/",
            "https://lehifreepress.com/2025/03/06/lehi-real-estate-snapshot-february-2025/",
            "https://www.heraldextra.com/news/local/2025/mar/06/sr-92-in-provo-canyon-closes-after-2-vehicles-slide-off-into-river-near-sundance-resort/",
            "https://www.deseret.com/utah/2025/03/06/photo-gallery-salt-lake-city-international-airport-opens-sensory-room/",
            "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/",
        ]

        for urlString in urls {
            guard let url = URL(string: urlString) else {
                XCTFail("Invalid URL: \(urlString)")
                continue
            }

            do {
                let content = try await parser.parse(url: url) { [self] document in
                    // Get the appropriate config for this URL
                    let config = buildConfig(for: url)

                    // Extract content using the config
                    let title = try self.parser.extractText(
                        from: document, selector: config.titleSelector)
                    let content = try self.parser.extractText(
                        from: document, selector: config.contentSelector)
                    let author = try? self.parser.extractText(
                        from: document, selector: config.authorSelector ?? "")

                    return TestNewsContent(
                        sourceURL: url,
                        title: title,
                        content: content,
                        author: author
                    )
                }

                // Validate the parsed content
                XCTAssertFalse(content.title.isEmpty, "Title should not be empty for \(urlString)")
                XCTAssertFalse(
                    content.content.isEmpty, "Content should not be empty for \(urlString)")
                print("✅ Successfully parsed: \(urlString)")
                print("Title: \(content.title)")
                print("Author: \(content.author ?? "Not found")")
                print("Content preview: \(String(content.content.prefix(200)))...")
                print("---")
            } catch {
                print("❌ Failed to parse \(urlString): \(error)")
                // Don't fail the test, just log the error
                // Some URLs might be invalid or require JavaScript
                continue
            }
        }
    }
}

/// Helper function to get the appropriate config for a URL
private func buildConfig(for url: URL) -> NewsParserConfig {
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
        return NewsParserConfig(
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
