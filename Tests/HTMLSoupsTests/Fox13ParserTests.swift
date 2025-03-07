import XCTest
@testable import HTMLSoups

final class AdaptiveParserFox13Tests: XCTestCase {
    var adaptiveParser: AdaptiveParser!
    
    override func setUp() async throws {
        adaptiveParser = AdaptiveParser()
    }
    
    func testAdaptiveParsingOnFox13Content() async throws {
        // Start with a single URL to test the basic functionality
        let url = URL(string: "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water")!
        
        // Add retry logic for network issues
        let maxRetries = 3
        var lastError: Error? = nil
        
        for attempt in 1...maxRetries {
            do {
                let parsedItem = try await adaptiveParser.parseAndLearn(url: url)
                XCTAssertFalse(parsedItem.title.isEmpty, "Title should not be empty")
                XCTAssertNotNil(parsedItem.textContent, "Content should not be nil")
                
                print("\n✅ Successfully parsed article using adaptive parser:")
                print("Title: \(parsedItem.title)")
                print("Author: \(parsedItem.author ?? "Not found")")
                if let content = parsedItem.textContent {
                    print("Content preview: \(String(content.prefix(200)))...")
                }
                
                // Get learned patterns
                let patterns = adaptiveParser.getCurrentConfig()
                print("\n💾 Current learned patterns:")
                print("Title selector: \(patterns.titleSelector)")
                print("Content selector: \(patterns.contentSelector)")
                print("Author selector: \(patterns.authorSelector ?? "None")")
                
                // If we get here, the test passed
                return
            } catch {
                lastError = error
                print("Attempt \(attempt) failed with error: \(error)")
                // Wait for a short time before retrying
                try await Task.sleep(nanoseconds: UInt64(1_000_000_000)) // 1 second
            }
        }
        
        // If we get here, all retries failed
        XCTFail("Failed to parse article after \(maxRetries) attempts. Last error: \(String(describing: lastError))")
    }
} 