import AppKit
@testable import quick_capture_raycast
import Testing

extension PasteboardReader {
    static func mock(_ string: String? = nil, returnsNil: Bool = false) -> PasteboardReader {
        .init {
            if returnsNil {
                return nil
            }
            return string
        }
    }
}

// MARK: - ClipboardContentTests

@Suite("Clipboard Content Tests")
struct ClipboardContentTests {
    @Test("Returns text when clipboard contains text")
    func getClipboardContentWithText() {
        let mockPasteboard = PasteboardReader.mock("Hello, World!")

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == "Hello, World!", "Should return the clipboard content")
    }

    @Test("Returns empty string when clipboard is empty")
    func getClipboardContentWithEmptyString() {
        let mockPasteboard = PasteboardReader.mock("")

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == "", "Should return empty string")
    }

    @Test("Returns nil when clipboard has no string content")
    func getClipboardContentWithNil() {
        let mockPasteboard = PasteboardReader.mock(returnsNil: true)

        let result = getClipboardContent(pasteboard: mockPasteboard)

        #expect(result == nil, "Should return nil when clipboard has no string content")
    }
}
