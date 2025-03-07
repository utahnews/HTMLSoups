import Foundation

/// Configuration for parsing news content
public struct NewsParserConfig {
    public let titleSelector: String
    public let contentSelector: String
    public let authorSelector: String?
    public let dateSelector: String?
    public let imageSelectors: [String]
    public let topicSelectors: [String]
    public let organizationSelectors: [String]
    public let locationSelectors: [String]
    
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