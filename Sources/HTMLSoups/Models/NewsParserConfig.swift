import Foundation

/// Configuration for parsing news content
public struct NewsParserConfig {
    public var titleSelector: String
    public var contentSelector: String
    public var authorSelector: String?
    public var dateSelector: String?
    public var imageSelectors: [String]
    public var topicSelectors: [String]
    public var organizationSelectors: [String]
    public var locationSelectors: [String]
    
    public init(
        titleSelector: String,
        contentSelector: String,
        authorSelector: String? = nil,
        dateSelector: String? = nil,
        imageSelectors: [String] = [],
        topicSelectors: [String] = [],
        organizationSelectors: [String] = [],
        locationSelectors: [String] = []
    ) {
        self.titleSelector = titleSelector
        self.contentSelector = contentSelector
        self.authorSelector = authorSelector
        self.dateSelector = dateSelector
        self.imageSelectors = imageSelectors
        self.topicSelectors = topicSelectors
        self.organizationSelectors = organizationSelectors
        self.locationSelectors = locationSelectors
    }
} 