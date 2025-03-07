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
        
        print("🔍 Testing URL: \(url.absoluteString)")
        print("Fetching and parsing content...")
        
        let startTime = Date()
        let article = try await adaptiveParser.parseAndLearn(from: url)
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n📝 Parsing Results:")
        print("------------------")
        print("Title: \(article.title)")
        print("Author: \(article.author ?? "Not found")")
        print("Published: \(article.publishedAt)")
        print("\nContent Preview: \(String(article.textContent?.prefix(200) ?? "") + "...")")
        
        print("\n🔗 Relationships:")
        print("---------------")
        
        let relationshipsByType = Dictionary(grouping: article.relationships) { $0.type }
        
        if let topics = relationshipsByType[EntityType.category] {
            print("\nTopics:")
            topics.forEach { print("- \($0.displayName ?? "Unnamed topic")") }
        }
        
        if let organizations = relationshipsByType[EntityType.organization] {
            print("\nOrganizations:")
            organizations.forEach { print("- \($0.displayName ?? "Unnamed organization")") }
        }
        
        if let locations = relationshipsByType[EntityType.location] {
            print("\nLocations:")
            locations.forEach { print("- \($0.displayName ?? "Unnamed location")") }
        }
        
        print("\n⏱ Processing Time: \(String(format: "%.2f", duration))s")
        
        print("\n🧠 Learned Selectors:")
        print("------------------")
        print("Title: \(adaptiveParser.getLearnedSelectors(for: "title").joined(separator: ", "))")
        print("Content: \(adaptiveParser.getLearnedSelectors(for: "content").joined(separator: ", "))")
        print("Author: \(adaptiveParser.getLearnedSelectors(for: "author").joined(separator: ", "))")
        print("Date: \(adaptiveParser.getLearnedSelectors(for: "date").joined(separator: ", "))")
    }
    
    /// Test parsing multiple URLs
    public func testURLs(_ urlStrings: [String]) async {
        print("🔄 Testing \(urlStrings.count) URLs...")
        print("===================")
        
        var successCount = 0
        var failureCount = 0
        let startTime = Date()
        
        for urlString in urlStrings {
            do {
                try await testURL(urlString)
                successCount += 1
            } catch {
                print("❌ Failed to process \(urlString): \(error.localizedDescription)")
                failureCount += 1
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("\n📊 Summary:")
        print("Total URLs: \(urlStrings.count)")
        print("Successes: \(successCount)")
        print("Failures: \(failureCount)")
        print("Success rate: \(String(format: "%.1f%%", Double(successCount) / Double(urlStrings.count) * 100))")
        print("Total time: \(String(format: "%.2f", duration))s")
        print("Average time per URL: \(String(format: "%.2f", duration / Double(urlStrings.count)))s")
    }
} 