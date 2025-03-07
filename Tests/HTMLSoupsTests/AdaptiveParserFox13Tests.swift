import XCTest
@testable import HTMLSoups

final class AdaptiveParserFox13Tests: XCTestCase {
    var parser: AdaptiveParser!
    
    override func setUp() async throws {
        parser = await AdaptiveParser()
    }
    
    override func tearDown() async throws {
        parser = nil
    }
    
    func testAdaptiveParsingOnFox13Content() async throws {
        let url = URL(string: "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water")!
        
        let article = try await parser.parseAndLearn(url: url)
        
        XCTAssertFalse(article.title.isEmpty, "Title should not be empty")
        XCTAssertFalse(article.textContent?.isEmpty ?? true, "Content should not be empty")
        XCTAssertGreaterThan(article.textContent?.count ?? 0, 100, "Content should have meaningful length")
    }
    
    func testAdaptiveParsingAcrossUtahNewsSites() async throws {
        let urls = [
            "https://www.abc4.com/news/politics/inside-utah-politics/utahs-latest-alcohol-bill-revived/",
            "https://www.fox13now.com/news/politics/dentist-shares-worries-concerns-for-kids-over-fluoride-removal-from-utahs-water",
            "https://www.sltrib.com/news/politics/2025/03/06/pride-flags-banned-utah-schools/",
            "https://www.ksl.com/article/51267799/utah-family-says-they-were-targeted-in-racially-motivated-verbal-assault",
            "https://kutv.com/news/2news-investigates/radio-interference-big-buildings-pay-their-way-for-new-utah-communications-system",
            "https://lehifreepress.com/2025/03/05/public-hearing-for-2100-n-environmental-study-thursday/",
            "https://lehifreepress.com/2025/03/06/lehi-real-estate-snapshot-february-2025/",
            "https://www.heraldextra.com/news/local/2025/mar/06/sr-92-in-provo-canyon-closes-after-2-vehicles-slide-off-into-river-near-sundance-resort/",
            "https://www.deseret.com/utah/2025/03/06/photo-gallery-salt-lake-city-international-airport-opens-sensory-room/",
            "https://www.deseret.com/sports/2025/03/06/alex-jensen-hired-utah-basketball-head-coach/",
            "https://www.deseret.com/sports/2025/03/04/byu-basketball-beats-iowa-state/",
            "https://www.fox13now.com/news/local-news/northern-utah/this-mansion-in-salt-lake-city-holds-part-of-slcs-beer-history-welcome-to-the-fisher-mansion",
            "https://www.sltrib.com/news/politics/2025/03/06/social-security-tax-be-cut-utahns/"
        ].map { URL(string: $0)! }
        
        var successCount = 0
        var failureCount = 0
        var siteStats: [String: (successes: Int, failures: Int)] = [:]
        
        for url in urls {
            do {
                let article = try await parser.parseAndLearn(url: url)
                let host = url.host ?? "unknown"
                
                // Check if parsing was successful
                let hasTitle = !article.title.isEmpty
                let hasContent = article.textContent?.count ?? 0 > 100
                
                if hasTitle && hasContent {
                    successCount += 1
                    siteStats[host] = (siteStats[host]?.successes ?? 0 + 1, siteStats[host]?.failures ?? 0)
                } else {
                    failureCount += 1
                    siteStats[host] = (siteStats[host]?.successes ?? 0, siteStats[host]?.failures ?? 0 + 1)
                    print("\n⚠️ Parsed but with issues: \(url.absoluteString)")
                    print("Has title: \(hasTitle)")
                    print("Has content: \(hasContent)")
                }
            } catch {
                failureCount += 1
                let host = url.host ?? "unknown"
                siteStats[host] = (siteStats[host]?.successes ?? 0, siteStats[host]?.failures ?? 0 + 1)
                print("\n❌ Failed to parse \(url.absoluteString): \(error)")
            }
        }
        
        // Print statistics
        print("\n📊 Overall Statistics:")
        print("Total URLs: \(urls.count)")
        print("Successful parses: \(successCount)")
        print("Failed parses: \(failureCount)")
        
        print("\nPer-site Statistics:")
        for (host, stats) in siteStats.sorted(by: { $0.key < $1.key }) {
            let total = Double(stats.successes + stats.failures)
            let successRate = total > 0 ? Double(stats.successes) / total * 100 : 0
            print("\(host):")
            print("- Successes: \(stats.successes)")
            print("- Failures: \(stats.failures)")
            print("- Success rate: \(String(format: "%.1f%%", successRate))")
        }
        
        // Verify overall success rate
        XCTAssertGreaterThan(successCount, urls.count / 2, "Should successfully parse more than half of the URLs")
    }
} 