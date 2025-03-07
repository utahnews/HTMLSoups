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
    
    func testBasicParsing() async throws {
        let url = URL(string: "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion")!
        
        // Parse and learn from the article
        let parsedItem = try await parser.parseAndLearn(url)
        
        // Verify basic parsing
        XCTAssertFalse(parsedItem.title.isEmpty, "Title should not be empty")
        XCTAssertGreaterThan(parsedItem.content.count, 100, "Content should be substantial")
        
        // Verify that the parser learned and updated its configuration
        let config = parser.getCurrentConfig()
        XCTAssertFalse(config.titleSelector.isEmpty, "Title selector should be learned")
        XCTAssertFalse(config.contentSelector.isEmpty, "Content selector should be learned")
    }
    
    func testAdaptiveParsing() async throws {
        let urls = [
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water",
            "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion"
        ].compactMap { URL(string: $0) }
        
        for url in urls {
            do {
                let article = try await parser.parseAndLearn(url)
                XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
                XCTAssertFalse(article.content.isEmpty, "Content should not be empty")
                print("✅ Successfully parsed \(url.absoluteString.components(separatedBy: "://").last ?? url.absoluteString):")
                print("Title: \(article.title)")
                print("Content length: \(article.content.count) characters")
            } catch {
                XCTFail("Failed to parse \(url.absoluteString): \(error)")
            }
        }
    }
    
    func testLearningPersistence() async throws {
        let url = URL(string: "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion")!
        
        // First parser instance
        let firstParser = await AdaptiveParser()
        _ = try await firstParser.parseAndLearn(url)
        let firstConfig = firstParser.getCurrentConfig()
        
        // Wait for Firebase to sync
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        // Second parser instance
        let secondParser = await AdaptiveParser()
        _ = try await secondParser.parseAndLearn(url)
        let secondConfig = secondParser.getCurrentConfig()
        
        print("\n🔄 Testing learning persistence:")
        print("First parser selectors:")
        print("- Title: \(firstConfig.titleSelector)")
        print("- Content: \(firstConfig.contentSelector)")
        print("\nSecond parser selectors:")
        print("- Title: \(secondConfig.titleSelector)")
        print("- Content: \(secondConfig.contentSelector)")
        
        // Verify learning persistence
        XCTAssertEqual(firstConfig.titleSelector, secondConfig.titleSelector, "Title selectors should match")
        XCTAssertEqual(firstConfig.contentSelector, secondConfig.contentSelector, "Content selectors should match")
    }
    
    func testCrossArticleLearning() async throws {
        let urls = [
            "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion",
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water"
        ].compactMap { URL(string: $0) }
        
        // First parser instance
        let firstParser = await AdaptiveParser()
        let firstArticle = try await firstParser.parseAndLearn(urls[0])
        
        // Wait for Firebase to sync
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        // Second parser instance
        let secondParser = await AdaptiveParser()
        let secondArticle = try await secondParser.parseAndLearn(urls[1])
        
        print("\n🔄 Testing cross-instance learning:")
        print("First article:")
        print("Title: \(firstArticle.title)")
        print("Content length: \(firstArticle.content.count) characters")
        print("\nSecond article:")
        print("Title: \(secondArticle.title)")
        print("Content length: \(secondArticle.content.count) characters")
        
        // Verify both articles were parsed successfully
        XCTAssertFalse(firstArticle.title.isEmpty, "First article title should not be empty")
        XCTAssertFalse(secondArticle.title.isEmpty, "Second article title should not be empty")
        XCTAssertGreaterThan(firstArticle.content.count, 100, "First article content should be substantial")
        XCTAssertGreaterThan(secondArticle.content.count, 100, "Second article content should be substantial")
    }
} 