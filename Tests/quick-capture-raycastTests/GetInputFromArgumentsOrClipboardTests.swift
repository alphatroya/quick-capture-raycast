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

        #expect(result.input == "Hello from args", "Should return command line argument")
        #expect(result.tags == nil, "Should have no tags when only input provided")
    }

    @Test("Returns command line argument and tags when both provided")
    func returnsCommandLineArgumentAndTags() throws {
        let arguments = ["program", "Hello from args", "work,personal"]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result.input == "Hello from args", "Should return command line argument")
        #expect(result.tags == "#work #personal", "Should parse tags correctly")
    }

    @Test("Returns clipboard content when no command line argument provided")
    func returnsClipboardContentWhenNoArgument() throws {
        let arguments = ["program"]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result.input == "Clipboard content", "Should return clipboard content")
        #expect(result.tags == nil, "Should have no tags when no tags argument provided")
    }

    @Test("Returns clipboard content and tags when tags argument provided")
    func returnsClipboardContentAndTags() throws {
        let arguments = ["program", "", "work,personal"]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result.input == "Clipboard content", "Should return clipboard content")
        #expect(result.tags == "#work #personal", "Should parse tags when provided with clipboard")
    }

    @Test("Returns clipboard content when empty command line argument provided")
    func returnsClipboardContentWhenEmptyArgument() throws {
        let arguments = ["program", ""]
        let mockPasteboard = PasteboardReader.mock("Clipboard content")

        let result = try getInputFromArgumentsOrClipboard(arguments: arguments, pasteboard: mockPasteboard)

        #expect(result.input == "Clipboard content", "Should return clipboard content when argument is empty")
        #expect(result.tags == nil, "Should have no tags when no tags argument provided")
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
