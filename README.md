# HTMLSoups

HTMLSoups is an adaptive HTML parsing library for Swift that learns and adapts to different website structures. It's specifically designed to handle content from various sites in Utah, but can be adapted for other use cases.

## Features

- 🧠 Adaptive Learning: Learns from successful parses to improve future attempts
- 🌐 Cross-Domain Support: Identifies common patterns across different domains
- 🔄 Dynamic Adaptation: Adapts to changes in website structures over time
- 📊 Confidence Scoring: Maintains confidence scores for different selectors
- 💾 Persistent Learning: Saves learned patterns for future use
- 🎯 Domain-Specific Patterns: Maintains specialized patterns for specific domains

## Installation

Add HTMLSoups to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import HTMLSoups
import UtahNewsData

// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let url = URL(string: "https://example.com/article")!
let article = try await parser.parseAndLearn(url)

print("Title: \(article.title)")
print("Content: \(article.content)")
print("Author: \(article.author ?? "Unknown")")
print("Date: \(article.date ?? "Unknown")")
```

### Custom Configuration

You can customize the parser with specific selectors:

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

// The parser automatically learns and adjusts its selectors
// based on successful parses
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

## Architecture

- `AdaptiveParser`: Main parser that adapts to different HTML structures
- `SelectorLearner`: Learning system that discovers and maintains CSS selectors
- `NewsParserConfig`: Configuration for parsing different types of content
- `NetworkManager`: Handles network requests with proper error handling

## Testing

The package includes extensive tests covering:
- Basic parsing functionality
- Adaptive learning capabilities
- Cross-domain pattern recognition
- Learning persistence
- Error handling

Run tests using:
```bash
swift test
```

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup): HTML parsing
- [UtahNewsData](https://github.com/utahnews/UtahNewsData): Utah news data models

## License

MIT License. See LICENSE file for details.
