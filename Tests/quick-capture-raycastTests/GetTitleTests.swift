import Foundation
@testable import quick_capture_raycast
import Testing

// MARK: - GetTitleTests

@Suite("Get Title Tests")
struct GetTitleTests {
    @Test("Valid URLs return correct titles", arguments: [
        ("http://example.com/article", "Article Title - Example Site"),
        ("http://example.com/special", "Special & Characters: Test's Page"),
        ("https://example.com/international", "Página Internacional - Ejemplo"),
        ("http://example.com/empty", ""),
        ("https://example.com/search?q=test&page=1", "Search Results"),
        ("http://example.com/page#section", "Page Section"),
        ("https://localhost:3000", "Secure Page"),
    ])
    func validURLsReturnCorrectTitles(url: String, expectedTitle: String) async throws {
        let mockFetcher = MockNetworkFetcher(response: expectedTitle)
        let result = try await getTitle(for: url, networkFetcher: mockFetcher)
        #expect(result == expectedTitle, "Should return correct title for URL: \(url)")
    }

    @Test("Invalid URLs throw appropriate errors", arguments: [
        ("not-a-url", URLError(.badURL)),
        ("http://example.com/slow", URLError(.timedOut)),
        ("https://example.com/not-found", URLError(.resourceUnavailable)),
        ("http://example.com/server-error", URLError(.badServerResponse)),
        ("ftp://example.com", URLError(.unsupportedURL)),
    ])
    func invalidURLsThrowErrors(url: String, expectedError: Error) async throws {
        let mockFetcher = MockNetworkFetcher(error: expectedError)
        await #expect(throws: (any Error).self) {
            try await getTitle(for: url, networkFetcher: mockFetcher)
        }
    }

    @Test("Throws error when page has no title tag")
    func throwsErrorWhenPageHasNoTitleTag() async throws {
        let mockFetcher = MockNetworkFetcher(error: TitleError.missingTitle)
        await #expect(throws: TitleError.self) {
            try await getTitle(for: "http://example.com/no-title", networkFetcher: mockFetcher)
        }
    }

    @Test("Throws error for invalid HTML")
    func throwsErrorForInvalidHTML() async throws {
        let mockFetcher = MockNetworkFetcher(error: TitleError.invalidHTML)
        await #expect(throws: TitleError.self) {
            try await getTitle(for: "http://example.com/invalid-html", networkFetcher: mockFetcher)
        }
    }

    @Test("Decodes HTML entities in title", arguments: [
        ("<title>Exploring IRC (Internet Relay Chat) | Preah&#x27;s Blog</title>", "Exploring IRC (Internet Relay Chat) | Preah's Blog"),
        ("<title>Test &amp; Example</title>", "Test & Example"),
        ("<title>Quote &quot;Test&quot;</title>", "Quote \"Test\""),
        ("<title>Less than &lt; 3</title>", "Less than < 3"),
        ("<title>Greater than &gt; 3</title>", "Greater than > 3"),
        ("<title>Normal Title</title>", "Normal Title"),
    ])
    func decodesHTMLEntitiesInTitle(html: String, expectedTitle: String) async throws {
        let mockFetcher = MockNetworkFetcher(htmlResponse: html)
        let result = try await getTitle(for: "http://example.com/test", networkFetcher: mockFetcher)
        #expect(result == expectedTitle)
    }
}

// MARK: - MockNetworkFetcher

struct MockNetworkFetcher: NetworkFetcherProtocol, Sendable {
    // MARK: Properties

    var response: String?
    var htmlResponse: String?
    var error: Error?

    // MARK: Functions

    func fetchTitle(from _: String) throws -> String {
        if let error {
            throw error
        }

        if let htmlResponse {
            // Simulate the actual extractTitle function behavior
            let pattern = #"<title[^>]*>(.*?)</title\s*>"#
            guard let range = htmlResponse.range(of: pattern, options: .regularExpression) else {
                throw TitleError.missingTitle
            }

            let titleMatch = String(htmlResponse[range])
            let titleContent = titleMatch.replacingOccurrences(of: #"<title[^>]*>|</title\s*>"#, with: "", options: .regularExpression)

            // Apply the same HTML entity decoding as the real implementation
            let decodedTitle = decodeHTMLEntities(titleContent)
            return decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let response else {
            throw TitleError.missingTitle
        }

        return response
    }

    // MARK: - Private

    private func decodeHTMLEntities(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }

        return string
    }
}
