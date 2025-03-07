/// ProjectOverview.swift
/// This file provides a high-level overview of the HTMLSoups project structure and functionality.
/// It serves as a quick reference for understanding the codebase's organization and key components.
///
/// Project Structure:
/// 1. Core Components
///    - HTMLContent.swift: Base protocol for HTML content extraction
///      * Defines the basic structure for extracted content
///      * Required properties: sourceURL, title, content, author
///      * Used by Article model and custom content types
///
///    - HTMLParser.swift: Core HTML parsing functionality
///      * Main parsing engine for HTML content
///      * Key methods:
///        - parse(url:contentExtractor:): Parses HTML from URL
///        - extractText(from:selector:): Extracts text using CSS selectors
///      * Handles basic HTML parsing and text extraction
///
///    - Article.swift: Article model and content structure
///      * Extends HTMLContent with news-specific fields
///      * Additional properties:
///        - publishedDate: Article publication date
///        - images: Array of image URLs
///        - topics: Article topics/categories
///        - organizations: Mentioned organizations
///        - locations: Mentioned locations
///
/// 2. Learning System
///    - SelectorLearner.swift: Learns and adapts CSS selectors
///      * Core learning functionality
///      * Key methods:
///        - learnSelectors(from:for:domain:knownContent:): Learns new selectors
///        - getLearnedSelectors(for:domain:): Retrieves learned selectors
///        - reportResult(selector:contentType:domain:success:): Updates learning
///      * Handles dynamic content detection
///
///    - LearningStorage.swift: Manages persistence of learned patterns
///      * Protocol for storing learned patterns
///      * Key methods:
///        - saveLearningData(_:completion:): Saves learning data
///        - loadLearningData(completion:): Loads learning data
///        - savePatternsForDomain(_:domain:completion:): Saves domain patterns
///        - loadPatternsForDomain(_:completion:): Loads domain patterns
///        - listLearnedDomains(completion:): Lists learned domains
///
///    - SelectorStorage.swift: Stores and retrieves selectors
///      * Manages selector persistence
///      * Key methods:
///        - saveSelectors(_:for:): Saves selectors for domain
///        - loadSelectors(for:): Loads selectors for domain
///        - listDomains(): Lists all domains with stored selectors
///
/// 3. Parser Components
///    - AdaptiveParser.swift: Main adaptive parsing system
///      * Combines parsing and learning
///      * Key methods:
///        - parseAndLearn(_:): Parses and learns from URL
///        - getCurrentConfig(): Gets current parser configuration
///      * Handles site-specific adaptations
///
///    - NewsParserConfig.swift: Configuration for news site parsing
///      * Defines parsing configuration
///      * Properties:
///        - titleSelector: Selector for article title
///        - contentSelector: Selector for article content
///        - authorSelector: Selector for author
///        - dateSelector: Selector for publication date
///        - imageSelectors: Selectors for images
///        - topicSelectors: Selectors for topics
///        - organizationSelectors: Selectors for organizations
///        - locationSelectors: Selectors for locations
///
/// 4. Tools
///    - NetworkManager.swift: Handles network requests
///      * Manages HTTP requests
///      * Key methods:
///        - fetchContent(from:): Fetches raw content
///        - fetchHTML(from:): Fetches and parses HTML
///      * Handles request retries and errors
///
///    - UserAgentManager.swift: Manages user agent rotation
///      * Handles user agent management
///      * Key methods:
///        - getNextUserAgent(): Gets next user agent
///        - rotateUserAgent(): Rotates to next user agent
///      * Prevents request blocking
///
/// 5. Extensions
///    - String+Extensions.swift: String manipulation utilities
///      * Extends String with HTML processing
///      * Key methods:
///        - cleanHTML(): Removes HTML tags
///        - extractText(): Extracts text content
///        - normalizeWhitespace(): Normalizes whitespace
///
/// Key Features:
/// - Adaptive HTML parsing
/// - Dynamic content detection
/// - Cross-site learning
/// - Persistent pattern storage
/// - Multi-site support
///
/// Usage Example:
/// ```swift
/// let parser = await AdaptiveParser()
/// let article = try await parser.parseAndLearn(url)
/// ```
///
/// Dependencies:
/// - SwiftSoup: HTML parsing
/// - Foundation: Core functionality
/// - Network: HTTP requests
///
/// Testing:
/// The project includes comprehensive tests in the Tests directory:
/// - SelectorLearnerTests.swift: Tests for selector learning
/// - AdaptiveParserTests.swift: Tests for adaptive parsing
/// - NetworkManagerTests.swift: Tests for network functionality
/// - MockLearningStorage.swift: Mock storage for testing
/// - Site-specific tests (Fox13, UtahNews)
