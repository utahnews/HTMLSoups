import Foundation
import HTMLSoups

let parser = await AdaptiveParser()

if CommandLine.arguments.count > 1 {
    let urlString = CommandLine.arguments[1]
    
    if urlString == "--help" || urlString == "-h" {
        print("""
        HTMLSoups CLI
        
        Usage:
          htmlsoups <url>          Parse a single URL
          htmlsoups --batch <file> Parse URLs from a file (one per line)
          htmlsoups --help         Show this help message
        """)
        exit(0)
    }
    
    if urlString == "--batch" {
        guard CommandLine.arguments.count > 2 else {
            print("Error: No file specified for batch processing")
            exit(1)
        }
        
        let filePath = CommandLine.arguments[2]
        do {
            let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
            let urls = fileContents.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
                .compactMap { URL(string: $0) }
            
            for url in urls {
                do {
                    let mediaItem = try await parser.parseAndLearn(url)
                    print("✅ Processed: \(url.lastPathComponent)")
                    print("   Title: \(mediaItem.title)")
                    if let date = mediaItem.publishDate {
                        print("   Published: \(date)")
                    }
                } catch {
                    print("❌ Failed to process \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error reading file: \(error.localizedDescription)")
            exit(1)
        }
    } else {
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            exit(1)
        }
        
        do {
            let startTime = Date()
            let mediaItem = try await parser.parseAndLearn(url)
            let duration = Date().timeIntervalSince(startTime)
            
            print("\n✅ Successfully parsed article")
            print("Title: \(mediaItem.title)")
            if let author = mediaItem.author {
                print("Author: \(author)")
            }
            if let date = mediaItem.publishDate {
                print("Published: \(date)")
            }
            print("\nProcessing time: \(String(format: "%.2f", duration))s")
        } catch {
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    }
} else {
    print("Error: No URL provided")
    print("Run 'htmlsoups --help' for usage information")
    exit(1)
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