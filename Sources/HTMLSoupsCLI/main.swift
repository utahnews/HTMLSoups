import Foundation
import HTMLSoups

Task {
    do {
        let parser = AdaptiveParser()
        
        if CommandLine.arguments.count < 2 {
            printUsage()
            exit(1)
        }
        
        let command = CommandLine.arguments[1]
        
        switch command {
        case "test":
            if CommandLine.arguments.count < 3 {
                print("Error: URL required for test command")
                printUsage()
                exit(1)
            }
            guard let url = URL(string: CommandLine.arguments[2]) else {
                print("Error: Invalid URL")
                exit(1)
            }
            
            print("🔍 Testing URL: \(url)")
            print("Fetching and parsing content...")
            
            let startTime = Date()
            let mediaItem = try await parser.parseAndLearn(url: url)
            let duration = Date().timeIntervalSince(startTime)
            
            print("\n📝 Parsing Results:")
            print("------------------")
            print("Title: \(mediaItem.title)")
            print("Author: \(mediaItem.author ?? "Not found")")
            print("Published: \(mediaItem.publishedAt)")
            print("\nContent Preview: \(String(mediaItem.textContent?.prefix(200) ?? "") + "...")")
            
            print("\n🔗 Relationships:")
            print("---------------")
            
            let relationshipsByType = Dictionary(grouping: mediaItem.relationships) { $0.type }
            
            if let topics = relationshipsByType[.category] {
                print("\nTopics:")
                topics.forEach { print("- \($0.displayName ?? "Unnamed topic")") }
            }
            
            if let organizations = relationshipsByType[.organization] {
                print("\nOrganizations:")
                organizations.forEach { print("- \($0.displayName ?? "Unnamed organization")") }
            }
            
            if let locations = relationshipsByType[.location] {
                print("\nLocations:")
                locations.forEach { print("- \($0.displayName ?? "Unnamed location")") }
            }
            
            print("\n⏱ Processing Time: \(String(format: "%.2f", duration))s")
            
            print("\n🧠 Learned Selectors:")
            print("------------------")
            print("Title: \(parser.getLearnedSelectors(for: "title").joined(separator: ", "))")
            print("Content: \(parser.getLearnedSelectors(for: "content").joined(separator: ", "))")
            print("Author: \(parser.getLearnedSelectors(for: "author").joined(separator: ", "))")
            print("Date: \(parser.getLearnedSelectors(for: "date").joined(separator: ", "))")
            
        case "batch":
            let urls = Array(CommandLine.arguments[2...])
            if urls.isEmpty {
                print("Error: At least one URL required for batch command")
                printUsage()
                exit(1)
            }
            
            print("🔄 Processing \(urls.count) URLs...")
            for urlString in urls {
                guard let url = URL(string: urlString) else {
                    print("⚠️ Skipping invalid URL: \(urlString)")
                    continue
                }
                
                do {
                    let mediaItem = try await parser.parseAndLearn(url: url)
                    print("✅ Processed: \(url.lastPathComponent)")
                    print("   Title: \(mediaItem.title)")
                    print("   Author: \(mediaItem.author ?? "Not found")")
                } catch {
                    print("❌ Failed to process \(url.lastPathComponent): \(error)")
                }
            }
            
            print("\n🧠 Final Learned Selectors:")
            print("-------------------------")
            print("Title: \(parser.getLearnedSelectors(for: "title").joined(separator: ", "))")
            print("Content: \(parser.getLearnedSelectors(for: "content").joined(separator: ", "))")
            print("Author: \(parser.getLearnedSelectors(for: "author").joined(separator: ", "))")
            print("Date: \(parser.getLearnedSelectors(for: "date").joined(separator: ", "))")
            
        default:
            print("Unknown command: \(command)")
            printUsage()
            exit(1)
        }
        exit(0)
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

dispatchMain()

func printUsage() {
    print("""
    Usage:
      HTMLSoupsCLI test <url>
      HTMLSoupsCLI batch <url1> <url2> ...
    
    Examples:
      HTMLSoupsCLI test https://www.deseret.com/example-article
      HTMLSoupsCLI batch https://site1.com/article https://site2.com/article
    """)
} 