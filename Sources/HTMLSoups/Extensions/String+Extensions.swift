/// This file provides useful extensions to the String type for HTMLSoups,
/// adding functionality for regular expression pattern matching and group
/// extraction. These extensions are used throughout the library for text
/// processing and pattern matching operations.
///
/// Key features:
/// - Regular expression pattern matching
/// - Capture group extraction
/// - Error handling for invalid patterns
///
/// This extension is used by:
/// - NetworkManager.swift: For extracting API endpoints
/// - SelectorLearner.swift: For pattern matching in content
/// - HTMLParser.swift: For text processing
///
/// The extensions provide a more Swift-friendly interface for working
/// with regular expressions and pattern matching.

import Foundation

extension String {
    /// Returns groups of a regular expression match
    /// - Parameter pattern: The regular expression pattern
    /// - Returns: An array of arrays, where each inner array contains the full match followed by each capture group
    public func groups(for pattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))

            return results.map { result in
                return (0..<result.numberOfRanges).map { index in
                    let rangeBounds = result.range(at: index)
                    guard let range = Range(rangeBounds, in: self) else { return "" }
                    return String(self[range])
                }
            }
        } catch {
            return []
        }
    }
}
