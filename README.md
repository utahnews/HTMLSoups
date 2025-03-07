# HTMLSoups

HTMLSoups is an adaptive HTML parsing library for Swift that learns and adapts to different website structures. It provides a flexible, generic HTML parsing solution that can be adapted for any website content.

## Features

- 🧠 Adaptive Learning: Learns from successful parses to improve future attempts
- 🌐 Cross-Domain Support: Identifies common patterns across different domains
- 🔄 Dynamic Adaptation: Adapts to changes in website structures over time
- 📊 Confidence Scoring: Maintains confidence scores for different selectors
- 💾 Persistent Learning: Saves learned patterns for future use
- 🎯 Domain-Specific Patterns: Maintains specialized patterns for specific domains
- 🔌 Pluggable Content Models: Use built-in generic models or create custom ones
- 🎨 Beautiful UI: Modern and intuitive interface for content extraction
- 🔍 Smart Selector Learning: Automatically learns and adapts CSS selectors
- 🛡️ Error Recovery: Robust error handling and recovery mechanisms

## Project Structure

The project is organized into several key components:

### 1. Core Components
- `HTMLContent.swift`: Base protocol for content extraction
- `HTMLParser.swift`: Core HTML parsing engine
- `Article.swift`: News article model with rich metadata

### 2. Learning System
- `SelectorLearner.swift`: Adaptive selector learning
- `LearningStorage.swift`: Pattern persistence
- `SelectorStorage.swift`: Selector management

### 3. Parser Components
- `AdaptiveParser.swift`: Main parsing system
- `NewsParserConfig.swift`: Site-specific configurations

### 4. Tools
- `NetworkManager.swift`: HTTP request handling
- `UserAgentManager.swift`: User agent rotation

### 5. Extensions
- `String+Extensions.swift`: HTML processing utilities

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import HTMLSoups

// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let url = URL(string: "https://example.com/article")!
let article = try await parser.parseAndLearn(url)

// Access parsed data
print("Title: \(article.title)")
print("Content: \(article.content)")
print("Author: \(article.author ?? "Unknown")")
print("Date: \(article.publishedDate ?? Date())")
print("Topics: \(article.topics.joined(separator: ", "))")
```

### Custom Content Models

Create your own content models by conforming to `HTMLContent`:

```swift
struct BlogPost: HTMLContent {
    let sourceURL: URL
    let title: String
    let content: String
    let author: String?
    
    // Add custom functionality
    var wordCount: Int {
        content.split(separator: " ").count
    }
}
```

### Advanced Features

#### Adaptive Learning

```swift
// The parser automatically learns from successful parses
let parser = await AdaptiveParser()
let article = try await parser.parseAndLearn(url)

// Access learned selectors
let config = parser.getCurrentConfig()
print("Title selector: \(config.titleSelector)")
print("Content selector: \(config.contentSelector)")
```

#### Dynamic Content Handling

```swift
// The parser automatically detects and handles dynamic content
let parser = await AdaptiveParser()
let article = try await parser.parseAndLearn(url)

// The parser learns to handle loading indicators and dynamic updates
```

## Testing

The project includes comprehensive tests:

```bash
# Run all tests
swift test

# Run specific test targets
swift test --target HTMLSoupsTests
swift test --target HTMLSoupsUtahNewsTests
```

Key test areas:
- Selector learning and adaptation
- Dynamic content handling
- Cross-domain pattern recognition
- Error recovery
- Network request handling
- Site-specific parsing (Fox13, UtahNews)

## Dependencies

- SwiftSoup: HTML parsing
- Foundation: Core functionality
- Network: HTTP requests

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
