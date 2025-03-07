import XCTest
import SwiftSoup
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
    
    func testCrossDomainLearning() async throws {
        // First site structure
        let html1 = """
        <html>
            <article>
                <h1 class="headline">Article One</h1>
                <div class="content">Content one</div>
            </article>
        </html>
        """
        
        // Second site with similar structure
        let html2 = """
        <html>
            <article>
                <h1 class="headline">Article Two</h1>
                <div class="content">Content two</div>
            </article>
        </html>
        """
        
        // Third site with different structure
        let html3 = """
        <html>
            <main>
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
        XCTAssertEqual(selectorsForSite2.first, "h1.headline", "Common pattern should be prioritized")
        
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
    
    func testConfidenceScoring() async throws {
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
        let confidence = learner.getSelectorConfidence(
            "h1.headline",
            contentType: "title",
            domain: "confidence.com"
        )
        XCTAssertGreaterThan(confidence, 0.8, "Confidence should increase with successful uses")
    }
} 