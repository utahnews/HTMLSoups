import Foundation

extension String {
    /// Returns groups of a regular expression match
    /// - Parameter pattern: The regular expression pattern
    /// - Returns: An array of arrays, where each inner array contains the full match followed by each capture group
    func groups(for pattern: String) -> [[String]] {
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