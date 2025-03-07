# HTMLSoups

HTMLSoups is an adaptive HTML parsing library for Swift that learns and adapts to different website structures. It's specifically designed to handle news content from various Utah news sites, but can be adapted for other use cases.

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

```swift
// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let url = URL(string: "https://example.com/article")!
let article = try await parser.parseAndLearn(url)

print("Title: \(article.title)")
print("Content: \(article.content)")
```

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
