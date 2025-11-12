import Foundation
@testable import quick_capture_raycast
import Testing

// MARK: - GetTitleTests

@Suite("Get Title Tests")
struct GetTitleTests {
    @Test("Returns title and final URL for redirect")
    func returnsTitleAndFinalURLForRedirect() async throws {
        let mockFetcher = MockNetworkFetcher(response: "Final Page Title", finalURL: "REDACTED__N34__/final-page")
        let (title, finalURL) = try await mockFetcher.fetchTitleAndFinalURL(from: "http://example.com/short-url")
        #expect(title == "Final Page Title")
        #expect(finalURL == "REDACTED__N34__/final-page")
    }

    @Test("Returns original URL when no redirect")
    func returnsOriginalURLWhenNoRedirect() async throws {
        let mockFetcher = MockNetworkFetcher(response: "Page Title")
        let (title, finalURL) = try await mockFetcher.fetchTitleAndFinalURL(from: "https://example.com/page")
        #expect(title == "Page Title")
        #expect(finalURL == "https://example.com/page")
    }
}

// MARK: - MockNetworkFetcher

struct MockNetworkFetcher: NetworkFetcherProtocol, Sendable {
    // MARK: Properties

    var response: String?
    var htmlResponse: String?
    var error: Error?
    var finalURL: String?

    // MARK: Functions

    func fetchTitleAndFinalURL(from url: String) async throws -> (title: String, finalURL: String) {
        if let error {
            throw error
        }

        if let htmlResponse {
            let title = try extractTitle(from: htmlResponse)
            return (title: title, finalURL: finalURL ?? url)
        }

        guard let response else {
            throw TitleError.missingTitle
        }

        return (title: response, finalURL: finalURL ?? url)
    }
}
