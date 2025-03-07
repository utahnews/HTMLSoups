import Foundation
import HTMLSoups
import HTMLSoupsUtahNews

// Create parser instance
let parser = await AdaptiveParser()

// Parse command line arguments
let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: HTMLSoupsCLI <command> <url>")
    exit(1)
}

let command = args[1]
let urlString = args[2]

guard let url = URL(string: urlString) else {
    print("Invalid URL: \(urlString)")
    exit(1)
}

// Execute command
do {
    switch command {
    case "parse":
        print("Parsing \(url)...")
        let article = try await parser.parseAndLearn(url) as Article
        
        print("\nResults:")
        print("   Title: \(article.title)")
        if let date = article.publishDate {
            print("   Date: \(date)")
        }
        if let author = article.author {
            print("   Author: \(author)")
        }
        print("   Content length: \(article.content.count) characters")
        if !article.topics.isEmpty {
            print("   Topics: \(article.topics.joined(separator: ", "))")
        }
        if !article.organizations.isEmpty {
            print("   Organizations: \(article.organizations.joined(separator: ", "))")
        }
        if !article.locations.isEmpty {
            print("   Locations: \(article.locations.joined(separator: ", "))")
        }
        
    case "learn":
        print("Learning from \(url)...")
        let article = try await parser.parseAndLearn(url) as Article
        
        print("\nLearned patterns from:")
        print("Title: \(article.title)")
        if let author = article.author {
            print("Author: \(author)")
        }
        if let date = article.publishDate {
            print("Date: \(date)")
        }
        print("Content length: \(article.content.count) characters")
        
    default:
        print("Unknown command: \(command)")
        exit(1)
    }
} catch {
    print("Error: \(error)")
    exit(1)
}

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