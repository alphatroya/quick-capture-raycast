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
}

// MARK: - MockNetworkFetcher

struct MockNetworkFetcher: NetworkFetcherProtocol, Sendable {
    // MARK: Properties

    private let response: String?
    private let error: Error?

    // MARK: Lifecycle

    init(response: String? = nil, error: Error? = nil) {
        self.response = response
        self.error = error
    }

    // MARK: Functions

    func fetchTitle(from _: String) throws -> String {
        if let error {
            throw error
        }
        guard let response else {
            throw TitleError.missingTitle
        }

        return response
    }
}
