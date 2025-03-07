# HTMLSoups

A Swift package for intelligent HTML parsing and content extraction.

Last Updated: 2024-03-21

## Overview

HTMLSoups is a powerful Swift package that provides intelligent HTML parsing and content extraction capabilities. It features an adaptive learning system that can automatically learn and adapt to different website structures, making it ideal for web scraping and content extraction tasks.

## Features

- Adaptive HTML parsing
- CSS selector learning
- Dynamic content handling
- Browser-like behavior
- Persistent learning
- Support for multiple news sources

## Installation

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/utahnews/HTMLSoups.git", from: "1.0.0")
]
```

## Usage

```swift
import HTMLSoups

// Create an adaptive parser
let parser = await AdaptiveParser()

// Parse an article
let article = try await parser.parseAndLearn(url: articleURL)
print(article.title)
print(article.content)
```

## Documentation

For detailed documentation, see the [Documentation](Sources/HTMLSoups/Documentation) directory.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
