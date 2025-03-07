import Foundation

/// A generic article model that can be used as a base for more specific implementations
public struct Article: HTMLContent {
    /// The source URL of the article
    public let sourceURL: URL
    
    /// The article's title
    public let title: String
    
    /// The main content of the article
    public let content: String
    
    /// The article's author (optional)
    public let author: String?
    
    /// The publication date (optional)
    public let publishDate: Date?
    
    /// Associated images (optional)
    public let images: [URL]
    
    /// Associated topics/categories (optional)
    public let topics: [String]
    
    /// Associated organizations (optional)
    public let organizations: [String]
    
    /// Associated locations (optional)
    public let locations: [String]
    
    public init(
        sourceURL: URL,
        title: String,
        content: String,
        author: String? = nil,
        publishDate: Date? = nil,
        images: [URL] = [],
        topics: [String] = [],
        organizations: [String] = [],
        locations: [String] = []
    ) {
        self.sourceURL = sourceURL
        self.title = title
        self.content = content
        self.author = author
        self.publishDate = publishDate
        self.images = images
        self.topics = topics
        self.organizations = organizations
        self.locations = locations
    }
} 