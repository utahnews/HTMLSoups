import Foundation
import SwiftSoup
import UtahNewsData

// Extension to support UtahNewsData models
extension HTMLParser {
    /// Configuration for parsing news content
    public typealias NewsParserConfig = HTMLSoups.NewsParserConfig
    
    /// Parses HTML content into a MediaItem with associated entities
    /// - Parameters:
    ///   - url: The URL to parse
    ///   - config: Configuration for parsing different elements
    /// - Returns: A MediaItem with associated relationships
    public func parseNewsContent(url: URL, config: NewsParserConfig) async throws -> MediaItem {
        return try await parse(url: url) { [self] document in
            // Extract basic content
            let title = try self.extractText(from: document, selector: config.titleSelector)
            
            // Extract article content with better handling of paragraphs
            let contentBuilder = try document.select(config.contentSelector)
                .flatMap { article -> [Element] in
                    // First try to find specific content containers
                    let contentContainers = try article.select(".ArticleBody, .article-body, .story-body, .entry-content").array()
                    if !contentContainers.isEmpty {
                        return contentContainers
                    }
                    // Fallback to all paragraphs in the article
                    return try article.select("p").array()
                }
                .map { try $0.text() }
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
            
            // Clean up content (remove "Published on By" prefixes and other common artifacts)
            let cleanedContent = contentBuilder
                .replacingOccurrences(of: "^Published\\s+on\\s+By\\s+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^Posted\\s+on\\s+By\\s+", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Enhanced author extraction with multiple patterns
            var author: String? = nil
            
            // Try the selector-based approach first
            if let authorSelector = config.authorSelector {
                author = try? self.extractText(from: document, selector: authorSelector)
                    .replacingOccurrences(of: "^By:?\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^Posted\\s+by\\s+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // If no author found, try to extract from content with regex patterns
            if author == nil || author?.isEmpty == true {
                // Look for patterns like "By Author Name" at the beginning of content
                let byPatterns = [
                    "By\\s+([\\w\\s\\.]+?)\\s+(?:on|in|\\||$)",
                    "By:?\\s+([\\w\\s\\.]+?)(?:\\.|,|\\||$)"
                ]
                
                for pattern in byPatterns {
                    if let match = contentBuilder.groups(for: pattern).first, 
                       match.count > 1 {
                        author = match[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
            
            // Enhanced date parsing
            var publishedDate: Date = Date()
            if let dateString = try? self.extractText(from: document, selector: config.dateSelector ?? "") {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                // Common date formats used by news sites
                let dateFormats = [
                    "yyyy-MM-dd'T'HH:mm:ssZ",           // ISO 8601
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",       // ISO 8601 with milliseconds
                    "yyyy-MM-dd HH:mm:ss",              // Standard datetime
                    "MMM d, yyyy 'at' h:mm a",          // Mar 7, 2025 at 2:30 PM
                    "MMMM d, yyyy 'at' h:mm a",         // March 7, 2025 at 2:30 PM
                    "MMM d, yyyy h:mm a",               // Mar 7, 2025 2:30 PM
                    "MMMM d, yyyy h:mm a",              // March 7, 2025 2:30 PM
                    "MMM d, yyyy",                      // Mar 7, 2025
                    "MMMM d, yyyy",                     // March 7, 2025
                    "MM/dd/yyyy HH:mm:ss",             // 03/07/2025 14:30:00
                    "MM/dd/yyyy"                       // 03/07/2025
                ]
                
                for format in dateFormats {
                    dateFormatter.dateFormat = format
                    if let date = dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        publishedDate = date
                        break
                    }
                }
            }
            
            // Extract relationships
            var relationships: [Relationship] = []
            
            // Topics/Categories
            for selector in config.topicSelectors {
                if let topics = try? self.extractTextArray(from: document, selector: selector) {
                    for topic in topics {
                        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanTopic.isEmpty {
                            relationships.append(Relationship(
                                id: UUID().uuidString,
                                type: .category,
                                displayName: cleanTopic,
                                context: "Topic extracted from article"
                            ))
                        }
                    }
                }
            }
            
            // Organizations
            for selector in config.organizationSelectors {
                if let organizations = try? self.extractTextArray(from: document, selector: selector) {
                    for org in organizations {
                        let cleanOrg = org.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleanOrg.isEmpty && !cleanOrg.contains("©") {  // Filter out copyright notices
                            relationships.append(Relationship(
                                id: UUID().uuidString,
                                type: .organization,
                                displayName: cleanOrg,
                                context: "Organization mentioned in article"
                            ))
                        }
                    }
                }
            }
            
            // Locations
            for selector in config.locationSelectors {
                if let locations = try? self.extractTextArray(from: document, selector: selector) {
                    for location in locations {
                        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "^in\\s+", with: "", options: .regularExpression)
                        if !cleanLocation.isEmpty {
                            relationships.append(Relationship(
                                id: UUID().uuidString,
                                type: .location,
                                displayName: cleanLocation,
                                context: "Location mentioned in article"
                            ))
                        }
                    }
                }
            }
            
            // Create and return the media item
            return MediaItem(
                id: url.absoluteString,
                title: title,
                type: .article,
                url: url.absoluteString,
                textContent: cleanedContent,
                author: author,
                publishedAt: publishedDate,
                relationships: relationships
            )
        }
    }
} 