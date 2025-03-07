# HTMLSoups

A flexible Swift library for parsing HTML content from various web pages using SwiftSoup. This library provides a clean and type-safe way to extract structured data from HTML pages with different layouts.

## Features

- Async/await based HTML fetching and parsing
- Flexible parsing configuration for different website structures
- Type-safe content models
- Error handling for network and parsing errors
- Helper methods for common parsing operations

## Installation

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "YOUR_REPOSITORY_URL", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
let parser = HTMLParser()

// Create a configuration for parsing a specific website's structure
let config = ArticleParserConfig(
    titleSelector: "h1.article-title",
    authorSelector: "span.author-name",
    contentSelector: "div.article-content",
    dateSelector: "time.published-date",
    imageSelector: "img.article-image"
)

// Parse an article
do {
    let article = try await parser.parseArticle(
        url: URL(string: "https://example.com/article")!,
        config: config
    )
    
    print("Title: \(article.title)")
    print("Author: \(article.author ?? "Unknown")")
    print("Content: \(article.content)")
} catch {
    print("Error: \(error)")
}
```

### Custom Content Models

You can create your own content models by conforming to the `HTMLContent` protocol:

```swift
struct ProductInfo: HTMLContent {
    let sourceURL: URL
    let name: String
    let price: Decimal
    let description: String
    let specifications: [String: String]
}

extension HTMLParser {
    func parseProduct(url: URL) async throws -> ProductInfo {
        try await parse(url: url) { document in
            // Your parsing logic here
            let name = try extractText(from: document, selector: "h1.product-name")
            let priceText = try extractText(from: document, selector: "span.price")
            // ... more parsing ...
            
            return ProductInfo(
                sourceURL: url,
                name: name,
                price: Decimal(string: priceText) ?? 0,
                description: description,
                specifications: specs
            )
        }
    }
}
```

## Error Handling

The library provides specific error cases through `HTMLParsingError`:

- `invalidURL`: The provided URL is not valid
- `networkError`: Network-related errors during fetching
- `parsingError`: HTML parsing errors
- `invalidSelector`: Invalid CSS selector
- `elementNotFound`: Element not found for the given selector

## License

This project is licensed under the MIT License - see the LICENSE file for details. 