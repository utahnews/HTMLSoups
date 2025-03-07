import Foundation

/// For a comprehensive overview of this file and its relationships with other components,
/// see Sources/HTMLSoups/Documentation/ProjectOverview.swift
///
/// This file defines the configuration structure for parsing news content in HTMLSoups.
/// It provides a flexible way to specify CSS selectors for different aspects of news
/// articles, allowing for customization of how content is extracted from various
/// news websites.
///
/// Key features:
/// - Configurable selectors for all article components
/// - Support for optional fields (author, date)
/// - Multiple selector support for images and metadata
/// - Flexible configuration for different website structures
///
/// This configuration is used by:
/// - AdaptiveParser.swift: For parsing news content
/// - Article.swift: For structuring parsed content
/// - SelectorLearner.swift: For learning and validating selectors
///
/// The configuration can be customized per website to handle different
/// HTML structures and content organization patterns.

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
