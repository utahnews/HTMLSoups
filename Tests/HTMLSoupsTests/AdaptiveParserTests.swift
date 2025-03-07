import XCTest
@testable import HTMLSoups

final class AdaptiveParserTests: XCTestCase {
    var parser: AdaptiveParser!
    
    override func setUp() async throws {
        parser = await AdaptiveParser()
    }
    
    override func tearDown() async throws {
        parser = nil
    }
    
    func testLearningFromSingleArticle() async throws {
        let url = URL(string: "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/")!
        
        // Parse and learn from the article
        let parsedItem = try await parser.parseAndLearn(url: url)
        let firstConfig = parser.getCurrentConfig()
        
        // Verify basic parsing
        XCTAssertFalse(parsedItem.title.isEmpty, "Title should not be empty")
        XCTAssertTrue(parsedItem.textContent?.count ?? 0 > 100, "Content should have meaningful length")
    }
    
    func testParsingMultipleStyles() async throws {
        let urls = [
            "https://www.lehifreepress.com/2025/03/06/lehi-real-estate-snapshot-february-2025/",
            "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/",
            "https://www.heraldextra.com/news/local/2025/mar/06/sr-92-in-provo-canyon-closes-after-2-vehicles-slide-off-into-river-near-sundance-resort/"
        ].map { URL(string: $0)! }
        
        var successCount = 0
        
        for url in urls {
            do {
                let article = try await parser.parseAndLearn(url: url)
                print("\n✅ Successfully parsed: \(url.absoluteString)")
                print("Title: \(article.title)")
                print("Content length: \(article.textContent?.count ?? 0) characters")
                print("Current selectors:")
                print("- Title: \(parser.getCurrentConfig().titleSelector)")
                print("- Content: \(parser.getCurrentConfig().contentSelector)")
                print("- Author: \(parser.getCurrentConfig().authorSelector ?? "none")")
                print("---")
                
                if !article.title.isEmpty && article.textContent?.count ?? 0 > 100 {
                    successCount += 1
                }
            } catch {
                print("\n❌ Failed to parse \(url.absoluteString): \(error)")
            }
        }
        
        XCTAssertGreaterThanOrEqual(successCount, 2, "Should successfully parse at least 2 out of 3 URLs")
    }
    
    func testLearningPersistence() async throws {
        let url = URL(string: "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/")!
        
        // First parser instance
        let firstParser = await AdaptiveParser()
        let firstArticle = try await firstParser.parseAndLearn(url: url)
        let firstConfig = firstParser.getCurrentConfig()
        
        // Wait for Firebase to sync
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        // Second parser instance
        let secondParser = await AdaptiveParser()
        let secondArticle = try await secondParser.parseAndLearn(url: url)
        let secondConfig = secondParser.getCurrentConfig()
        
        print("\n🔄 Testing learning persistence:")
        print("First parser config:")
        print("- Title: \(firstConfig.titleSelector)")
        print("- Content: \(firstConfig.contentSelector)")
        print("\nSecond parser config:")
        print("- Title: \(secondConfig.titleSelector)")
        print("- Content: \(secondConfig.contentSelector)")
        
        XCTAssertEqual(firstConfig.titleSelector, secondConfig.titleSelector)
        XCTAssertEqual(firstConfig.contentSelector, secondConfig.contentSelector)
    }
    
    func testCrossInstanceLearning() async throws {
        let urls = [
            "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/",
            "https://www.deseret.com/sports/2025/03/04/byu-basketball-beats-iowa-state/"
        ].map { URL(string: $0)! }
        
        // First parser instance
        let firstParser = await AdaptiveParser()
        let firstArticle = try await firstParser.parseAndLearn(url: urls[0])
        let firstConfig = firstParser.getCurrentConfig()
        
        // Wait for Firebase to sync
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        // Second parser instance
        let secondParser = await AdaptiveParser()
        let secondArticle = try await secondParser.parseAndLearn(url: urls[1])
        
        print("\n🔄 Testing cross-instance learning:")
        print("First article (Parser 1):")
        print("- Title: \(firstArticle.title)")
        print("- Content length: \(firstArticle.textContent?.count ?? 0)")
        print("\nSecond article (Parser 2):")
        print("- Title: \(secondArticle.title)")
        print("- Content length: \(secondArticle.textContent?.count ?? 0)")
        
        XCTAssertFalse(firstArticle.title.isEmpty, "First article should have title")
        XCTAssertFalse(secondArticle.title.isEmpty, "Second article should have title")
        XCTAssertGreaterThan(firstArticle.textContent?.count ?? 0, 100, "First article should have content")
        XCTAssertGreaterThan(secondArticle.textContent?.count ?? 0, 100, "Second article should have content")
    }
} 