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
- Automatic documentation updates
- Robust error handling
- Swift 5.9 compatibility
- Comprehensive system dependency management

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

### Automatic Updates

This project uses GitHub Actions to automatically update documentation when changes are made to the codebase. The following files are automatically maintained:

- ProjectOverview.swift: Updated when source files change
- README.md: Updated when documentation changes
- File headers: Updated with last modified dates

The documentation update system includes robust error handling and detailed logging to ensure reliable updates. The system runs on Swift 5.9 and is tested against the latest Swift toolchain, with comprehensive system dependency management for reliable builds.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
