/// This file contains comprehensive tests for the SelectorLearner class, which is responsible
/// for learning and adapting CSS selectors for HTML content extraction. The tests cover
/// various aspects of the learning system including initial learning, dynamic content
/// detection, cross-domain learning, and adaptation to site changes.
///
/// Key test areas:
/// - Initial selector learning and persistence
/// - Dynamic content detection and handling
/// - Cross-domain pattern recognition
/// - Site structure adaptation
/// - Loading indicator handling
/// - Selector confidence scoring
/// - Complex dynamic content scenarios
///
/// Dependencies:
/// - SelectorLearner.swift: The main class being tested
/// - MockLearningStorage.swift: For mocking storage operations
/// - SwiftSoup: For HTML parsing in tests

import SwiftSoup
import XCTest

@testable import HTMLSoups

final class SelectorLearnerTests: XCTestCase {
    var learner: SelectorLearner!
    var mockStorage: MockLearningStorage!

    override func setUp() async throws {
        mockStorage = MockLearningStorage()
        learner = await SelectorLearner(storage: mockStorage)
    }

    override func tearDown() async throws {
        learner = nil
        mockStorage = nil
    }

    func testInitialLearning() async throws {
        let html = """
            <html>
                <article>
                    <h1 class="headline">Test Article</h1>
                    <div class="article-content">Test content</div>
                    <span class="author">John Doe</span>
                    <time class="published-date">2025-03-06</time>
                </article>
            </html>
            """

        let document = try SwiftSoup.parse(html)

        // Test initial learning
        let titleSelectors = try learner.learnSelectors(
            from: document,
            for: "title",
            domain: "test.com",
            knownContent: "Test Article"
        )

        XCTAssertTrue(titleSelectors.contains("h1.headline"))

        // Verify learning was persisted
        let newLearner = await SelectorLearner(storage: mockStorage)
        let loadedSelectors = try newLearner.learnSelectors(
            from: document,
            for: "title",
            domain: "test.com"
        )

        XCTAssertTrue(loadedSelectors.contains("h1.headline"))
    }

    func testDynamicContentDetection() async throws {
        // Test HTML with dynamic content indicators
        let html = """
            <html>
                <div class="loading-spinner">Loading...</div>
                <div class="dynamic-content" data-article-id="123">
                    <h1 class="article-title">Test Article</h1>
                    <div class="article-content">
                        <p>This is the main content</p>
                        <div class="loading-indicator">Loading more content...</div>
                    </div>
                </div>
            </html>
            """

        let document = try SwiftSoup.parse(html)

        // Test title selector learning
        let titleSelectors = try learner.learnSelectors(
            from: document,
            for: "title",
            domain: "test.com",
            knownContent: "Test Article"
        )

        // Verify that dynamic content selectors were discovered
        XCTAssertTrue(titleSelectors.contains("h1.article-title"))
        XCTAssertTrue(titleSelectors.contains("div.dynamic-content h1"))

        // Test content selector learning
        let contentSelectors = try learner.learnSelectors(
            from: document,
            for: "content",
            domain: "test.com",
            knownContent: "This is the main content"
        )

        // Verify that content selectors were discovered
        XCTAssertTrue(contentSelectors.contains("div.article-content"))
        XCTAssertTrue(contentSelectors.contains("div.dynamic-content .article-content"))
    }

    func testCrossDomainLearning() async throws {
        // First site with dynamic content
        let html1 = """
            <html>
                <div class="loading">Loading...</div>
                <article class="dynamic-article">
                    <h1 class="headline">Article One</h1>
                    <div class="content">Content one</div>
                </article>
            </html>
            """

        // Second site with similar structure
        let html2 = """
            <html>
                <div class="spinner">Loading...</div>
                <article class="dynamic-article">
                    <h1 class="headline">Article Two</h1>
                    <div class="content">Content two</div>
                </article>
            </html>
            """

        // Third site with different structure
        let html3 = """
            <html>
                <div class="wait">Loading...</div>
                <main class="dynamic-main">
                    <h2 class="title">Article Three</h2>
                    <section class="body">Content three</section>
                </main>
            </html>
            """

        let doc1 = try SwiftSoup.parse(html1)
        let doc2 = try SwiftSoup.parse(html2)
        let doc3 = try SwiftSoup.parse(html3)

        // Learn from first site
        _ = try learner.learnSelectors(
            from: doc1,
            for: "title",
            domain: "site1.com",
            knownContent: "Article One"
        )

        // Learn from second site
        let selectorsForSite2 = try learner.learnSelectors(
            from: doc2,
            for: "title",
            domain: "site2.com",
            knownContent: "Article Two"
        )

        // Verify cross-domain pattern recognition
        XCTAssertTrue(selectorsForSite2.contains("h1.headline"))
        XCTAssertEqual(
            selectorsForSite2.first, "h1.headline", "Common pattern should be prioritized")

        // Learn from third site
        let selectorsForSite3 = try learner.learnSelectors(
            from: doc3,
            for: "title",
            domain: "site3.com",
            knownContent: "Article Three"
        )

        // Verify adaptation to different structure
        XCTAssertTrue(selectorsForSite3.contains("h2.title"))
    }

    func testAdaptationToSiteChanges() async throws {
        // Original site structure
        let oldHTML = """
            <html>
                <article>
                    <h1 class="headline">Original Article</h1>
                    <div class="content">Original content</div>
                </article>
            </html>
            """

        // Updated site structure
        let newHTML = """
            <html>
                <article>
                    <h1 class="new-headline">Updated Article</h1>
                    <div class="new-content">Updated content</div>
                </article>
            </html>
            """

        let oldDoc = try SwiftSoup.parse(oldHTML)
        let newDoc = try SwiftSoup.parse(newHTML)

        // Learn original structure
        _ = try learner.learnSelectors(
            from: oldDoc,
            for: "title",
            domain: "changing.com",
            knownContent: "Original Article"
        )

        // Learn new structure
        let updatedSelectors = try learner.learnSelectors(
            from: newDoc,
            for: "title",
            domain: "changing.com",
            knownContent: "Updated Article"
        )

        // Verify adaptation to new structure
        XCTAssertTrue(updatedSelectors.contains("h1.new-headline"))

        // Verify both patterns are maintained
        let allSelectors = learner.getLearnedSelectors(for: "title", domain: "changing.com")
        XCTAssertTrue(allSelectors.contains("h1.headline"))
        XCTAssertTrue(allSelectors.contains("h1.new-headline"))
    }

    func testLoadingIndicatorHandling() async throws {
        // Test HTML with multiple loading indicators
        let html = """
            <html>
                <div class="loading-spinner">Loading...</div>
                <div class="dynamic-content">
                    <div class="loading-indicator">Loading article...</div>
                    <article>
                        <h1>Test Article</h1>
                        <div class="content">Main content</div>
                    </article>
                    <div class="loading-more">Loading more...</div>
                </div>
            </html>
            """

        let document = try SwiftSoup.parse(html)

        // Test content selector learning
        let contentSelectors = try learner.learnSelectors(
            from: document,
            for: "content",
            domain: "test.com",
            knownContent: "Main content"
        )

        // Verify that content was found despite loading indicators
        XCTAssertTrue(contentSelectors.contains("div.content"))
        XCTAssertTrue(contentSelectors.contains("article .content"))
    }

    func testSelectorConfidenceScoring() async throws {
        let html = """
            <html>
                <article>
                    <h1 class="headline">Test Article</h1>
                    <div class="content">Test content</div>
                </article>
            </html>
            """

        let document = try SwiftSoup.parse(html)

        // Initial learning
        _ = try learner.learnSelectors(
            from: document,
            for: "title",
            domain: "confidence.com",
            knownContent: "Test Article"
        )

        // Report successful uses
        learner.reportResult(
            selector: "h1.headline",
            contentType: "title",
            domain: "confidence.com",
            success: true
        )
        learner.reportResult(
            selector: "h1.headline",
            contentType: "title",
            domain: "confidence.com",
            success: true
        )

        // Verify confidence increase
        let confidence = learner.getSelectorConfidence("h1.headline")
        XCTAssertGreaterThan(confidence, 1.0, "Confidence should increase after successful use")
    }

    func testComplexDynamicContent() async throws {
        // Test HTML with complex dynamic content structure
        let html = """
            <html>
                <div class="loading-overlay">
                    <div class="spinner">Loading...</div>
                </div>
                <div class="dynamic-container" data-article="true">
                    <div class="article-header">
                        <h1 class="title">Complex Article</h1>
                        <div class="meta">
                            <span class="author">John Doe</span>
                            <time class="date">2025-03-06</time>
                        </div>
                    </div>
                    <div class="article-body">
                        <div class="loading-section">Loading section...</div>
                        <div class="content-section">
                            <p>First paragraph</p>
                            <div class="dynamic-ad">Advertisement</div>
                            <p>Second paragraph</p>
                        </div>
                        <div class="loading-more">Loading more content...</div>
                    </div>
                </div>
            </html>
            """

        let document = try SwiftSoup.parse(html)

        // Test learning multiple content types
        let titleSelectors = try learner.learnSelectors(
            from: document,
            for: "title",
            domain: "complex.com",
            knownContent: "Complex Article"
        )

        let contentSelectors = try learner.learnSelectors(
            from: document,
            for: "content",
            domain: "complex.com",
            knownContent: "First paragraph"
        )

        let authorSelectors = try learner.learnSelectors(
            from: document,
            for: "author",
            domain: "complex.com",
            knownContent: "John Doe"
        )

        // Verify selectors were learned correctly
        XCTAssertTrue(titleSelectors.contains("h1.title"))
        XCTAssertTrue(contentSelectors.contains("div.content-section"))
        XCTAssertTrue(authorSelectors.contains("span.author"))

        // Verify dynamic content handling
        XCTAssertTrue(contentSelectors.contains("div.dynamic-container .content-section"))
    }
}
