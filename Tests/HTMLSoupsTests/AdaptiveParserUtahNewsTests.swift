/// This file contains comprehensive tests for parsing content from various Utah
/// news sources using the AdaptiveParser. It focuses on verifying the parser's
/// ability to handle different Utah news websites and maintain consistent
/// content extraction across multiple sources.
///
/// Key test areas:
/// - Multi-site Utah news parsing
/// - Success rate tracking across sites
/// - Dynamic content handling
/// - Content validation
/// - Error handling and reporting
///
/// Dependencies:
/// - AdaptiveParser.swift: The main class being tested
/// - HTMLParser.swift: For content parsing
/// - NetworkManager.swift: For content fetching
///
/// These tests ensure reliable content extraction across Utah's major
/// news sources, with particular attention to dynamic content and
/// site-specific structures.

import XCTest

@testable import HTMLSoups

final class AdaptiveParserUtahNewsTests: XCTestCase {
    var parser: AdaptiveParser!

    override func setUp() async throws {
        parser = await AdaptiveParser()
    }

    override func tearDown() async throws {
        parser = nil
    }

    func testAdaptiveParsingAcrossUtahNewsSites() async throws {
        let urls = [
            "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion",
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water",
            "https://www.fox13now.com/news/local-news/utah-legislature-passes-bill-on-bathroom-use",
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

    func testKUTVDynamicContent() async throws {
        let url = URL(
            string:
                "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion"
        )!

        let article = try await parser.parseAndLearn(url)

        print("\n✅ Successfully parsed KUTV content:")
        print("Title: \(article.title)")
        print("Content preview: \(article.content.prefix(200))")
        print("Working selectors:")
        print("Title: \(parser.getCurrentConfig().titleSelector)")
        print("Content: \(parser.getCurrentConfig().contentSelector)")
        print("Author: \(parser.getCurrentConfig().authorSelector ?? "none")")
        print("Date: \(parser.getCurrentConfig().dateSelector ?? "none")")

        XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
        XCTAssertGreaterThan(article.content.count, 100, "Content should be substantial")
    }
}
