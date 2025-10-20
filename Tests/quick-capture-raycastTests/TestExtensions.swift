import Foundation
@testable import quick_capture_raycast
import Testing

// MARK: - PasteboardReader Extensions

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

// MARK: - MockFileHandle

final class MockFileHandle: FileHandleProtocol, @unchecked Sendable {
    // MARK: Properties

    private let onSeekToEndOfFile: () -> UInt64
    private let onWrite: (Data) -> Void
    private let onCloseFile: () -> Void

    // MARK: Lifecycle

    init(
        onSeekToEndOfFile: @escaping () -> UInt64 = { 0 },
        onWrite: @escaping (Data) -> Void = { _ in },
        onCloseFile: @escaping () -> Void = {},
    ) {
        self.onSeekToEndOfFile = onSeekToEndOfFile
        self.onWrite = onWrite
        self.onCloseFile = onCloseFile
    }

    // MARK: Functions

    func seekToEndOfFile() -> UInt64 {
        onSeekToEndOfFile()
    }

    func write(_ data: Data) {
        onWrite(data)
    }

    func closeFile() {
        onCloseFile()
    }
}

// MARK: - FileManagerWrapper Extensions

extension FileWorker {
    static func mock(
        homeDirectoryPath: @Sendable @escaping () -> String = { "/Users/testuser" },
        fileExistsAtPath: @Sendable @escaping (String) -> Bool = { _ in false },
        createDirectoryAtPath: @Sendable @escaping (String, Bool, [FileAttributeKey: Any]?) throws -> Void = { _, _, _ in },
        contentsAtPath: @Sendable @escaping (String) throws -> String? = { _ in nil },
        writeStringToFile: @Sendable @escaping (String, String, Bool, String.Encoding) throws -> Void = { _, _, _, _ in },
        fileHandleForWritingToPath: @Sendable @escaping (String) throws -> FileHandleProtocol = { _ in
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        },
    ) -> FileWorker {
        .init(
            homeDirectoryPath: homeDirectoryPath,
            fileExistsAtPath: fileExistsAtPath,
            createDirectoryAtPath: createDirectoryAtPath,
            contentsAtPath: contentsAtPath,
            writeStringToFile: writeStringToFile,
            fileHandleForWritingToPath: fileHandleForWritingToPath,
        )
    }
}
