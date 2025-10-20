import AppKit
@testable import quick_capture_raycast
import Testing

// MARK: - GetInputFromArgumentsOrClipboardTests

@Suite("Get Input From Arguments Or Clipboard Tests")
struct GetInputFromArgumentsOrClipboardTests {
    @Test("Returns command line argument when provided")
    func returnsCommandLineArgument() throws {
        let arguments = ["program", "Hello from args"]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result == "Hello from args", "Should return command line argument")
    }

    @Test("Returns clipboard content when no command line argument provided")
    func returnsClipboardContentWhenNoArgument() throws {
        let arguments = ["program"]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result == "Clipboard content", "Should return clipboard content")
    }

    @Test("Returns clipboard content when empty command line argument provided")
    func returnsClipboardContentWhenEmptyArgument() throws {
        let arguments = ["program", ""]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result == "Clipboard content", "Should return clipboard content when argument is empty")
    }

    @Test("Throws error when no input and empty clipboard")
    func throwsErrorWhenNoInputAndEmptyClipboard() {
        let arguments = ["program"]
        let mockPasteboard = PasteboardReader.mock("")

        #expect(throws: InputError.noInputAvailable) {
            try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)
        }
    }

    @Test("Throws error when empty argument and empty clipboard")
    func throwsErrorWhenEmptyArgumentAndEmptyClipboard() {
        let arguments = ["program", ""]
        let mockPasteboard = PasteboardReader.mock("")

        #expect(throws: InputError.noInputAvailable) {
            try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)
        }
    }

    @Test("Throws error when clipboard has nil content")
    func throwsErrorWhenClipboardHasNilContent() {
        let arguments = ["program"]
        let mockPasteboard = PasteboardReader.mock(returnsNil: true)

        #expect(throws: InputError.noInputAvailable) {
            try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)
        }
    }
}
