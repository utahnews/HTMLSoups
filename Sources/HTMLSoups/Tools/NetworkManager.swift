import Foundation

/// This file implements a robust network manager for HTMLSoups that handles all
/// HTTP requests with browser-like behavior. It provides functionality for fetching
/// both static and dynamic content, handling various content types, and managing
/// network-related configurations.
///
/// Key features:
/// - Browser-like headers and behavior
/// - Dynamic content detection and fetching
/// - API endpoint discovery
/// - User-Agent rotation
/// - Charset detection
///
/// This manager is used by:
/// - HTMLParser.swift: For fetching HTML content
/// - SelectorLearner.swift: For learning patterns from web content
/// - AdaptiveParser.swift: For fetching dynamic content
///
/// Dependencies:
/// - UserAgentManager.swift: For rotating User-Agent strings

/// Manages network requests with browser-like behavior
public class NetworkManager {
    /// Default timeout interval for requests (in seconds)
    private let defaultTimeout: TimeInterval = 30

    /// Shared URLSession instance
    private let session: URLSession

    /// UserAgentManager instance for rotating User-Agent strings
    private let userAgentManager = UserAgentManager.shared

    /// Common browser-like headers
    private var commonHeaders: [String: String] {
        [
            "Accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "DNT": "1",
        ]
    }

    /// Singleton instance
    public static let shared = NetworkManager()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = defaultTimeout
        self.session = URLSession(configuration: config)
    }

    /// Fetches HTML content from a URL with browser-like headers
    /// - Parameter url: The URL to fetch content from
    /// - Returns: The HTML content as a string
    public func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)

        // Add common headers
        for (key, value) in commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add rotating User-Agent
        request.setValue(userAgentManager.nextUserAgent(), forHTTPHeaderField: "User-Agent")

        // Add Referer if not homepage
        if !url.path.isEmpty && url.path != "/" {
            let referer = "\(url.scheme ?? "https")://\(url.host ?? "")"
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTMLParsingError.networkError(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTMLParsingError.networkError(URLError(.badServerResponse))
        }

        let encoding: String.Encoding
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
            let charset = contentType.split(separator: "=").last,
            let detectedEncoding = String.Encoding.from(charset: String(charset))
        {
            encoding = detectedEncoding
        } else {
            encoding = .utf8
        }

        guard let html = String(data: data, encoding: encoding) else {
            throw HTMLParsingError.parsingError(
                NSError(
                    domain: "HTMLSoups", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode response data"]))
        }

        return html
    }

    /// Simulates waiting for dynamic content to load
    /// - Parameter url: The URL being processed
    /// - Returns: Additional content loaded dynamically
    public func fetchDynamicContent(from url: URL) async throws -> String? {
        // Create XHR-like request headers
        var request = URLRequest(url: url)
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add common headers and User-Agent
        for (key, value) in commonHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(userAgentManager.nextUserAgent(), forHTTPHeaderField: "User-Agent")

        // Try to fetch dynamic content
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                return nil
            }

            // Check if response is JSON
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                contentType.contains("application/json")
            {
                return String(data: data, encoding: .utf8)
            }

            return nil
        } catch {
            return nil  // Silently fail for dynamic content
        }
    }

    /// Attempts to extract API endpoints from HTML
    /// - Parameter html: The HTML content to analyze
    /// - Returns: Array of potential API endpoints
    private func extractAPIEndpoints(from html: String) -> [URL] {
        var endpoints: [URL] = []

        // Common patterns for API endpoints
        let patterns = [
            "api/content/\\w+",
            "wp-json/wp/v2/posts",
            "api/articles",
            "_next/data",
            "graphql",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, options: [], range: range)

                for match in matches {
                    if let range = Range(match.range, in: html) {
                        let endpoint = String(html[range])
                        if let url = URL(string: endpoint) {
                            endpoints.append(url)
                        }
                    }
                }
            }
        }

        return endpoints
    }
}

// Extension to support charset detection
extension String.Encoding {
    fileprivate static func from(charset: String) -> String.Encoding? {
        switch charset.lowercased() {
        case "utf-8", "utf8":
            return .utf8
        case "iso-8859-1", "latin1":
            return .isoLatin1
        case "windows-1252":
            return .windowsCP1252
        default:
            return nil
        }
    }
}
