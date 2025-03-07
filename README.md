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

## Package Structure

HTMLSoups is organized into multiple targets to minimize dependencies:

- **HTMLSoups**: Core library with generic HTML parsing capabilities
- **HTMLSoupsUtahNews**: Optional extension for Utah news sites (requires UtahNewsData)
- **HTMLSoupsCLI**: Command-line interface for testing and development

## Installation

### Core Library Only

If you only need the generic HTML parsing capabilities:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]

// In your target dependencies:
dependencies: ["HTMLSoups"]
```

### With Utah News Support

If you need Utah news specific functionality:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]

// In your target dependencies:
dependencies: ["HTMLSoups", "HTMLSoupsUtahNews"]
```

## Usage

### Basic Usage with Generic Article Model

The core library provides a generic `Article` model for basic content parsing:

```swift
import HTMLSoups

// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let url = URL(string: "https://example.com/article")!
let article = try await parser.parseAndLearn(url) as Article

// Access parsed data
print("Title: \(article.title)")
print("Content: \(article.content)")
print("Author: \(article.author ?? "Unknown")")
print("Date: \(article.publishDate ?? Date())")
print("Topics: \(article.topics.joined(separator: ", "))")
```

### Custom Content Models

Create your own content models by conforming to `HTMLContent`:

```swift
struct BlogPost: HTMLContent {
    let sourceURL: URL
    let headline: String
    let body: String
    let tags: [String]
    let commentCount: Int
    
    // Add custom functionality
    var wordCount: Int {
        body.split(separator: " ").count
    }
}

// Use your custom model
let post = try await parser.parseAndLearn(url) as BlogPost
print("Headline: \(post.headline)")
print("Word count: \(post.wordCount)")
```

### Utah News Support (Optional)

If you've included HTMLSoupsUtahNews, you can use Utah news specific features:

```swift
import HTMLSoups
import HTMLSoupsUtahNews
import UtahNewsData

// Create a parser with Utah news configuration
let parser = await AdaptiveParser()
let mediaItem = try await parser.parseNewsContent(url: url)

// Access Utah news specific data
print("Title: \(mediaItem.title)")
print("Organizations: \(mediaItem.relationships.filter { $0.type == .organization })")
```

### Custom Configuration

Configure the parser with specific selectors:

```swift
let config = NewsParserConfig(
    titleSelector: "h1.article-title",
    contentSelector: "div.article-content",
    authorSelector: "span.author-name",
    dateSelector: "time.published-date",
    imageSelectors: ["img.article-image"],
    topicSelectors: ["span.topic"],
    organizationSelectors: ["span.org-name"],
    locationSelectors: ["span.location"]
)

let parser = await AdaptiveParser(config: config)
```

### Advanced Features

#### Persistent Learning

```swift
// Save learned patterns
try await parser.saveLearnedPatterns()

// Load previously learned patterns
let parser = await AdaptiveParser(loadLearnedPatterns: true)
```

#### Custom Network Configuration

```swift
let config = NetworkConfig(
    timeout: 30,
    cachePolicy: .returnCacheDataElseLoad,
    headers: ["User-Agent": "HTMLSoups/1.0"]
)

let parser = await AdaptiveParser(networkConfig: config)
```

## Best Practices

1. **Start Simple**: Begin with the core HTMLSoups library and the generic Article model
2. **Custom Models**: Create custom models only when you need specific functionality
3. **Error Handling**: Implement proper error handling for network and parsing failures
4. **Learning**: Allow the parser to learn from multiple sources within the same domain
5. **Validation**: Validate parsed content before using the results
6. **Rate Limiting**: Implement appropriate rate limiting when parsing multiple articles

## Testing

### Unit Tests

```bash
# Test core functionality
swift test --target HTMLSoupsTests

# Test Utah news functionality (if available)
swift test --target HTMLSoupsUtahNewsTests
```

### CLI Testing

```bash
# Parse a URL
swift run HTMLSoupsCLI parse "https://example.com/article"

# Learn from a URL
swift run HTMLSoupsCLI learn "https://example.com/article"
```

### Test Configuration

```bash
# Set environment variables for testing
export HTMLSOUPS_TIMEOUT=30
export HTMLSOUPS_USER_AGENT="HTMLSoups/1.0"
export HTMLSOUPS_DEBUG=1

# Run with configuration
HTMLSOUPS_DEBUG=1 swift run HTMLSoupsCLI parse "https://example.com/article"
```

## Dependencies

Core Library:
- [SwiftSoup](https://github.com/scinfu/SwiftSoup): HTML parsing

Optional (HTMLSoupsUtahNews only):
- [UtahNewsData](https://github.com/utahnews/UtahNewsData): Utah news data models

## License

MIT License. See LICENSE file for details.
