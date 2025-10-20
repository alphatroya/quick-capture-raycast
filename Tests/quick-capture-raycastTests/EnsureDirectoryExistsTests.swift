import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Ensure Directory Exists Tests")
struct EnsureDirectoryExistsTests {
    @Test("Creates directory when it doesn't exist")
    func createsDirectoryWhenPathDoesNotExist() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in false },
                createDirectoryAtPath: { path, _, _ in
                    continuation.resume(returning: path == "/test/path")
                },
            )
            do {
                try ensureDirectoryExists(at: "/test/path", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Directory should be created when path doesn't exist")
    }

    @Test("Does nothing when directory exist")
    func returnsTrueWhenDirectoryAlreadyExists() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in true },
                createDirectoryAtPath: { _, _, _ in
                    throw NSError(domain: "TestError", code: 1)
                },
            )
            do {
                try ensureDirectoryExists(at: "/test/path", fileManager: mockFileWorker)
                continuation.resume(returning: true)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Should succeed when directory already exists")
    }

    @Test("Handles directory creation failure")
    func throwsErrorWhenDirectoryCreationFails() throws {
        let mockFileWorker = FileWorker.mock(
            fileExistsAtPath: { _ in false },
            createDirectoryAtPath: { _, _, _ in
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            },
        )
        #expect(throws: (any Error).self) {
            try ensureDirectoryExists(at: "/test/path", fileManager: mockFileWorker)
        }
    }

    @Test("Creates intermediate directories if not exists")
    func createsIntermediateDirectoriesForNestedPath() async throws {
        let result: Bool = try await withCheckedThrowingContinuation { continuation in
            let mockFileWorker = FileWorker.mock(
                fileExistsAtPath: { _ in false },
                createDirectoryAtPath: { path, createIntermediates, _ in
                    continuation.resume(returning: path == "/test/nested/path" && createIntermediates)
                },
            )
            do {
                try ensureDirectoryExists(at: "/test/nested/path", fileManager: mockFileWorker)
            } catch {
                continuation.resume(throwing: error)
            }
        }

        #expect(result == true, "Should create intermediate directories for nested path")
    }
}
