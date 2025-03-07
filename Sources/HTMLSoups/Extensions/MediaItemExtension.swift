import Foundation
import UtahNewsData

extension MediaItem: HTMLContent {
    public var sourceURL: URL {
        URL(string: url) ?? URL(string: "about:blank")!
    }
} 