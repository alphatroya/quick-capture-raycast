import AppKit
@testable import quick_capture_raycast
import Testing

// Mock PasteboardProtocol for testing
class MockPasteboard: PasteboardProtocol {
    var mockString: String?
    var shouldReturnNil = false

    func string(forType _: NSPasteboard.PasteboardType) -> String? {
        if shouldReturnNil {
            return nil
        }
        return mockString
    }
}

@Suite("Clipboard Content Tests")
struct ClipboardContentTests {
    @Test("Returns text when clipboard contains text")
    func getClipboardContentWithText() {
        let mockPasteboard = MockPasteboard()
        mockPasteboard.mockString = "Hello, World!"

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == "Hello, World!", "Should return the clipboard content")
    }

    @Test("Returns empty string when clipboard is empty")
    func getClipboardContentWithEmptyString() {
        let mockPasteboard = MockPasteboard()
        mockPasteboard.mockString = ""

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == "", "Should return empty string")
    }

    @Test("Returns nil when clipboard has no string content")
    func getClipboardContentWithNil() {
        let mockPasteboard = MockPasteboard()
        mockPasteboard.shouldReturnNil = true

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == nil, "Should return nil when clipboard has no string content")
    }
}
