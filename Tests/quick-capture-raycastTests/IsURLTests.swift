import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Is URL Tests")
struct IsURLTests {
    @Test("Valid HTTP URLs return true", arguments: [
        "http://example.com",
        "http://example.com/path/to/resource",
        "https://example.com/search?q=test&page=1",
        "http://example.com:8080",
        "https://example.com/page#section",
        "http://subdomain.example.com",
        "https://api.v2.example.com",
        "https://localhost:3000",
        "https://例子.com",
        "http://xn--fsq.com",
    ])
    func validHttpURLs(_ url: String) {
        let result = isURL(url)
        #expect(result == true, "Should return true for valid HTTP URL: \(url)")
    }

    @Test("Invalid URLs return false", arguments: [
        "",
        "   ",
        "ftp://example.com",
        "mailto:test@example.com",
        "file:///path/to/file",
        "tel:+1234567890",
        "data:text/plain;base64,SGVsbG8=",
        "example.com",
        "htp://example.com",
        " http://example.com\n"
    ])
    func invalidURLs(_ url: String) {
        let result = isURL(url)
        #expect(result == false, "Should return false for invalid URL: \(url)")
    }
}
