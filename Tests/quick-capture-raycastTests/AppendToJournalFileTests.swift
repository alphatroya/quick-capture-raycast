import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Append To Journal File Tests")
struct AppendToJournalFileTests {
    @Test("Creates new file when file doesn't exist")
    func createsNewFileWhenFileDoesNotExist() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in false },
                writeStringToFile: { content, path, atomically, encoding in
                    continuation.resume(
                        returning:
                        path == "/test/journal.md" &&
                            content == "Test content" &&
                            atomically == true &&
                            encoding == .utf8,
                    )
                },
            )
            do {
                try appendToJournalFile(at: "/test/journal.md", content: "Test content", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Should create new file with correct content")
    }

    @Test("Appends content to existing file without trailing newline")
    func appendsContentToFileWithoutTrailingNewline() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileHandle = MockFileHandle(
                onSeekToEndOfFile: { 0 },
                onWrite: { data in
                    let writtenString = String(data: data, encoding: .utf8)
                    continuation.resume(returning: writtenString == "\nNew content")
                },
            )

            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in true },
                contentsAtPath: { _ in "Existing content" },
                fileHandleForWritingToPath: { _ in mockFileHandle },
            )

            do {
                try appendToJournalFile(at: "/test/journal.md", content: "New content", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Should append content with newline prefix when file has no trailing newline")
    }

    @Test("Appends content to existing file with trailing newline")
    func appendsContentToFileWithTrailingNewline() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileHandle = MockFileHandle(
                onSeekToEndOfFile: { 0 },
                onWrite: { data in
                    let writtenString = String(data: data, encoding: .utf8)
                    continuation.resume(returning: writtenString == "New content")
                },
            )

            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in true },
                contentsAtPath: { _ in "Existing content\n" },
                fileHandleForWritingToPath: { _ in mockFileHandle },
            )

            do {
                try appendToJournalFile(at: "/test/journal.md", content: "New content", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Should append content without extra newline when file already has trailing newline")
    }

    @Test("Handles file reading error")
    func throwsErrorWhenFileReadingFails() throws {
        let mockFileWorker = FileWorker.mock(
            fileExistsAtPath: { _ in true },
            contentsAtPath: { _ in
                throw NSError(domain: "TestError", code: 1)
            },
        )

        #expect(throws: (any Error).self) {
            try appendToJournalFile(at: "/test/journal.md", content: "Test content", fileManager: mockFileWorker)
        }
    }

    @Test("Handles file creation error")
    func throwsErrorWhenFileCreationFails() throws {
        let mockFileWorker = FileWorker.mock(
            fileExistsAtPath: { _ in false },
            writeStringToFile: { _, _, _, _ in
                throw NSError(domain: "TestError", code: 1)
            },
        )

        #expect(throws: (any Error).self) {
            try appendToJournalFile(at: "/test/journal.md", content: "Test content", fileManager: mockFileWorker)
        }
    }

    @Test("Handles empty existing file")
    func appendsContentToEmptyFile() async throws {
        let result: String = try await withCheckedThrowingContinuation { continuation in
            let mockFileHandle = MockFileHandle(
                onSeekToEndOfFile: { 0 },
                onWrite: { data in
                    let writtenString = String(data: data, encoding: .utf8)
                    continuation.resume(returning: writtenString!)
                },
            )

            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in true },
                contentsAtPath: { _ in "" },
                fileHandleForWritingToPath: { _ in mockFileHandle },
            )

            do {
                try appendToJournalFile(at: "/test/journal.md", content: "New content", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == "\nNew content", "Should append content to empty file with newline prefix")
    }
}
