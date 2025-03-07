import Foundation
import UtahNewsData

/// A class for testing the adaptive parser on various URLs
public class ParserTester {
    private let adaptiveParser: AdaptiveParser
    
    public init() async {
        self.adaptiveParser = await AdaptiveParser()
    }
    
    /// Test parsing a single URL
    public func testURL(_ urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw HTMLParsingError.invalidURL
        }
        
        print("\n📝 Testing URL: \(urlString)")
        print("---------------")
        
        let article = try await adaptiveParser.parseAndLearn(url)
        
        print("Title: \(article.title)")
        if let author = article.author {
            print("Author: \(author)")
        }
        if let date = article.publishDate {
            print("Date: \(date)")
        }
        print("\nContent Preview:")
        print(article.content.prefix(200))
        print("...")
        print("\nFull Content Length: \(article.content.count) characters")
        
        print("\n✅ Successfully parsed article")
    }
    
    /// Test parsing multiple URLs
    public func testURLs(_ urlStrings: [String]) async {
        var successCount = 0
        var failureCount = 0
        
        for urlString in urlStrings {
            do {
                try await testURL(urlString)
                successCount += 1
            } catch {
                print("\n❌ Failed to parse URL: \(urlString)")
                print("Error: \(error)")
                failureCount += 1
            }
        }
        
        print("\n📊 Summary:")
        print("---------------")
        print("Total URLs: \(urlStrings.count)")
        print("Successes: \(successCount)")
        print("Failures: \(failureCount)")
        print("Success Rate: \(Double(successCount) / Double(urlStrings.count) * 100)%")
    }
} 