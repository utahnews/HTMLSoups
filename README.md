# HTMLSoups

HTMLSoups is an adaptive HTML parsing library for Swift that learns and adapts to different website structures. While originally designed for Utah news sites, it's a generic HTML parsing solution that can be adapted for any website content.

## Features

- 🧠 Adaptive Learning: Learns from successful parses to improve future attempts
- 🌐 Cross-Domain Support: Identifies common patterns across different domains
- 🔄 Dynamic Adaptation: Adapts to changes in website structures over time
- 📊 Confidence Scoring: Maintains confidence scores for different selectors
- 💾 Persistent Learning: Saves learned patterns for future use
- 🎯 Domain-Specific Patterns: Maintains specialized patterns for specific domains
- 🔌 Pluggable Content Models: Use built-in generic models or create custom ones

## Installation

Add HTMLSoups to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]
```

## Usage

### Basic Usage with Generic Content

The simplest way to use HTMLSoups is with the built-in generic content model:

```swift
import HTMLSoups

// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let url = URL(string: "https://example.com/article")!
let content = try await parser.parseAndLearn(url) as GenericHTMLContent

// Access parsed data
print("Title: \(content.data["title"] ?? "Unknown")")
print("Content: \(content.data["content"] ?? "Unknown")")
print("Author: \(content.data["author"] ?? "Unknown")")
print("Date: \(content.data["date"] ?? "Unknown")")
```

### Custom Content Models

You can create your own content models by conforming to `HTMLContent`:

```swift
// Define your custom content model
struct NewsArticle: HTMLContent {
    let sourceURL: URL
    let headline: String
    let body: String
    let publishDate: Date?
    let author: String?
    
    // Implement any additional functionality
    var wordCount: Int {
        body.split(separator: " ").count
    }
}

// Use your custom model with the parser
let parser = await AdaptiveParser()
let article = try await parser.parseAndLearn(url) as NewsArticle
print("Headline: \(article.headline)")
print("Word count: \(article.wordCount)")
```

### Custom Configuration

You can customize the parser with specific selectors for any content type:

```swift
let config = NewsParserConfig(
    titleSelector: "h1.article-title",
    contentSelector: "div.article-content",
    authorSelector: "span.author-name",
    dateSelector: "time.published-date",
    imageSelectors: ["img.article-image", "div.hero-image img"],
    topicSelectors: ["span.topic", "a.category"],
    organizationSelectors: ["span.org-name"],
    locationSelectors: ["span.location"]
)

let parser = await AdaptiveParser(config: config)
```

### Learning and Adaptation

The parser learns from successful parses and adapts its selectors:

```swift
// Parse multiple articles to improve learning
let urls = [
    "https://news1.example.com/article1",
    "https://news2.example.com/article2"
].map { URL(string: $0)! }

for url in urls {
    do {
        let article = try await parser.parseAndLearn(url)
        print("Successfully parsed: \(article.title)")
    } catch {
        print("Failed to parse \(url): \(error)")
    }
}
```

### Error Handling

HTMLSoups provides detailed error handling:

```swift
do {
    let article = try await parser.parseAndLearn(url)
} catch ParserError.networkError(let error) {
    print("Network error: \(error)")
} catch ParserError.parsingError(let error) {
    print("Parsing error: \(error)")
} catch ParserError.invalidContent(let message) {
    print("Invalid content: \(message)")
} catch {
    print("Unknown error: \(error)")
}
```

### Advanced Features

#### Persistent Learning

The parser can save and load learned patterns:

```swift
// Save learned patterns
try await parser.saveLearnedPatterns()

// Load previously learned patterns
let parser = await AdaptiveParser(loadLearnedPatterns: true)
```

#### Custom Network Configuration

Configure network settings:

```swift
let config = NetworkConfig(
    timeout: 30,
    cachePolicy: .returnCacheDataElseLoad,
    headers: ["User-Agent": "HTMLSoups/1.0"]
)

let parser = await AdaptiveParser(networkConfig: config)
```

## Best Practices

1. **Error Handling**: Always implement proper error handling to manage network and parsing failures gracefully.
2. **Learning**: Allow the parser to learn from multiple sources within the same domain to improve accuracy.
3. **Configuration**: Start with specific selectors when you know the site structure, and let the parser adapt over time.
4. **Validation**: Validate parsed content to ensure quality before using the results.
5. **Rate Limiting**: Implement appropriate rate limiting when parsing multiple articles to respect website policies.
6. **Content Models**: Choose between generic and custom content models based on your needs:
   - Use `GenericHTMLContent` for quick prototyping or simple use cases
   - Create custom models for type-safe, domain-specific content

## Architecture

- `AdaptiveParser`: Main parser that adapts to different HTML structures
- `SelectorLearner`: Learning system that discovers and maintains CSS selectors
- `NewsParserConfig`: Configuration for parsing different types of content
- `NetworkManager`: Handles network requests with proper error handling
- `HTMLContent`: Protocol for creating custom content models
- `GenericHTMLContent`: Built-in generic content model

## Testing

The package includes extensive tests covering:
- Basic parsing functionality
- Adaptive learning capabilities
- Cross-domain pattern recognition
- Learning persistence
- Error handling

### Running Tests

Basic test execution:
```bash
swift test
```

### CLI Testing Tools

The package includes CLI tools for testing parser functionality:

```bash
# Test parsing a specific URL
swift run ParserTester parse "https://example.com/article"

# Test parsing with learning enabled
swift run ParserTester learn "https://example.com/article"

# Test parsing multiple URLs from a domain
swift run ParserTester domain "example.com" --count 5

# Test cross-domain learning
swift run ParserTester cross-domain \
    "https://site1.com/article" \
    "https://site2.com/article" \
    "https://site3.com/article"

# Save learning data after testing
swift run ParserTester learn "https://example.com/article" --save

# Load existing learning data for testing
swift run ParserTester learn "https://example.com/article" --load

# View detailed parsing results
swift run ParserTester parse "https://example.com/article" --verbose
```

### Test Configuration

You can configure test behavior using environment variables:

```bash
# Set timeout for network requests
export HTMLSOUPS_TIMEOUT=30

# Set user agent for requests
export HTMLSOUPS_USER_AGENT="HTMLSoups/1.0"

# Enable debug logging
export HTMLSOUPS_DEBUG=1

# Run tests with configuration
HTMLSOUPS_DEBUG=1 swift run ParserTester parse "https://example.com/article"
```

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup): HTML parsing

## License

MIT License. See LICENSE file for details.
