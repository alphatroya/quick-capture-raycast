import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Markdown URL Tests")
struct MarkdownURLTests {
    @Test("Returns markdown format for valid URL and title", arguments: [
        ("https://example.com", "Example Site", "[Example Site](https://example.com)"),
        ("https://example.com/article", "Article Title", "[Article Title](https://example.com/article)"),
        ("https://localhost:3000", "Localhost", "[Localhost](https://localhost:3000)"),
        ("https://example.com/path/to/page", "Page Title", "[Page Title](https://example.com/path/to/page)"),
        ("https://example.com/search?q=test", "Search Results", "[Search Results](https://example.com/search?q=test)"),
        ("https://example.com/page#section", "Section Title", "[Section Title](https://example.com/page#section)"),
        ("https://user:pass@example.com:8080", "Secure Site", "[Secure Site](https://user:pass@example.com:8080)"),
    ])
    func returnsMarkdownFormatForValidURLAndTitle(url: String, title: String, expected: String) async {
        let mockFetcher = MockNetworkFetcher(response: title)
        let result = await markdownURLIfNeeded(url, titleFetcher: mockFetcher)
        #expect(result == expected, "Should return markdown format for valid URL and title")
    }

    @Test("Returns raw URL for invalid URL regardless of title", arguments: [
        ("not-a-url", "Some Title", "not-a-url"),
        ("ftp://example.com", "FTP Site", "ftp://example.com"),
        ("mailto:test@example.com", "Email", "mailto:test@example.com"),
        ("file:///path/to/file", "File", "file:///path/to/file"),
        ("tel:+1234567890", "Phone", "tel:+1234567890"),
        ("data:text/plain;base64,SGVsbG8=", "Data URL", "data:text/plain;base64,SGVsbG8="),
        ("htp://example.com", "Invalid Protocol", "htp://example.com"),
        ("", "Empty URL", ""),
        ("   ", "Whitespace URL", "   ")
    ])
    func returnsRawURLForInvalidURL(url: String, title: String, expected: String) async {
        let mockFetcher = MockNetworkFetcher(response: title)
        let result = await markdownURLIfNeeded(url, titleFetcher: mockFetcher)
        #expect(result == expected, "Should return raw URL for invalid URL regardless of title")
    }

    @Test("Returns raw URL when title fetching fails")
    func returnsRawURLWhenTitleFetchingFails() async {
        let mockFetcher = MockNetworkFetcher(error: TitleError.invalidHTML)
        let result = await markdownURLIfNeeded("https://example.com/article", titleFetcher: mockFetcher)
        #expect(result == "https://example.com/article", "Should return raw URL when title fetching fails")
    }

    @Test("Returns markdown format when title fetching succeeds")
    func returnsMarkdownFormatWhenTitleFetchingSucceeds() async {
        let mockFetcher = MockNetworkFetcher(response: "Article Title")
        let result = await markdownURLIfNeeded("https://example.com/article", titleFetcher: mockFetcher)
        #expect(result == "[Article Title](https://example.com/article)", "Should return markdown format when title fetching succeeds")
    }

    @Test("Handles special characters in title", arguments: [
        ("https://example.com", "Title with & symbols", "[Title with & symbols](https://example.com)"),
        ("https://example.com", "Title with \"quotes\"", "[Title with \"quotes\"](https://example.com)"),
        ("https://example.com", "Title with <brackets>", "[Title with <brackets>](https://example.com)"),
        ("https://example.com", "Title with [brackets]", "[Title with [brackets]](https://example.com)"),
        ("https://example.com", "Title with (parentheses)", "[Title with (parentheses)](https://example.com)"),
    ])
    func handlesSpecialCharactersInTitle(url: String, title: String, expected: String) async {
        let mockFetcher = MockNetworkFetcher(response: title)
        let result = await markdownURLIfNeeded(url, titleFetcher: mockFetcher)
        #expect(result == expected, "Should handle special characters in title")
    }

    @Test("Returns raw URL when title is empty", arguments: [
        ("https://example.com/article", ""),
        ("https://example.com/article", "\t\n"),
        ("https://example.com/file", "  \t\n  ")
    ])
    func returnsRawURLWhenTitleIsEmpty(url: String, title: String) async {
        let mockFetcher = MockNetworkFetcher(response: title)
        let result = await markdownURLIfNeeded(url, titleFetcher: mockFetcher)
        #expect(result == url, "Should return raw URL when title is empty")
    }
}
