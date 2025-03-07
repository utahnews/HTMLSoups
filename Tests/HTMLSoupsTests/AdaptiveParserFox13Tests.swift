/// This file contains specific tests for parsing content from Fox 13 News,
/// focusing on the AdaptiveParser's ability to handle this particular news source.
/// The tests verify content extraction, learning, and adaptation specifically
/// for the Fox 13 website structure.
///
/// Key test areas:
/// - Fox 13 specific content parsing
/// - Adaptive learning for Fox 13 structure
/// - Success rate tracking
/// - Content validation
/// - Error handling
///
/// Dependencies:
/// - AdaptiveParser.swift: The main class being tested
/// - HTMLParser.swift: For content parsing
/// - NetworkManager.swift: For content fetching
///
/// These tests ensure reliable content extraction from Fox 13 News,
/// which is one of the primary news sources in Utah.

import XCTest

@testable import HTMLSoups

final class AdaptiveParserFox13Tests: XCTestCase {
    var parser: AdaptiveParser!

    override func setUp() async throws {
        parser = await AdaptiveParser()
    }

    override func tearDown() async throws {
        parser = nil
    }

    func testAdaptiveParsingOnFox13Content() async throws {
        let url = URL(
            string:
                "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water"
        )!

        let article = try await parser.parseAndLearn(url)

        XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
        XCTAssertGreaterThan(article.content.count, 100, "Content should be substantial")
    }

    func testAdaptiveParsingAcrossUtahNewsSites() async throws {
        let urls = [
            "https://www.fox13now.com/news/local-news/utah-legislature-passes-bill-on-bathroom-use",
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water",
            "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion",
        ].compactMap { URL(string: $0) }

        var successCount = 0
        var failureCount = 0

        for url in urls {
            do {
                let article = try await parser.parseAndLearn(url)
                let host = url.host ?? "unknown"

                print("\n✅ Successfully parsed \(host):")
                print("Title: \(article.title)")
                print("Content length: \(article.content.count) characters")

                XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
                XCTAssertGreaterThan(article.content.count, 100, "Content should be substantial")

                successCount += 1
            } catch {
                print("\n❌ Failed to parse \(url.host ?? "unknown"): \(error)")
                failureCount += 1
            }
        }

        print("\n📊 Summary:")
        print("Total URLs: \(urls.count)")
        print("Successes: \(successCount)")
        print("Failures: \(failureCount)")

        XCTAssertGreaterThan(
            Double(successCount) / Double(urls.count), 0.5,
            "Should successfully parse more than half of the URLs")
    }
}
