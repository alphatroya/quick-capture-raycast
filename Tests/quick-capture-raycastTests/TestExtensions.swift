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

// MARK: - FileManagerWrapper Extensions

extension FileWorker {
    static func mock(
        homeDirectoryPath: @Sendable @escaping () -> String = { "/Users/testuser" },
        fileExistsAtPath: @Sendable @escaping (String) -> Bool = { _ in false },
        createDirectoryAtPath: @Sendable @escaping (String, Bool, [FileAttributeKey: Any]?) throws -> Void = { _, _, _ in },
        contentsAtPath: @Sendable @escaping (String) throws -> String? = { _ in nil },
        writeStringToFile: @Sendable @escaping (String, String, Bool, String.Encoding) throws -> Void = { _, _, _, _ in },
    ) -> FileWorker {
        .init(
            homeDirectoryPath: homeDirectoryPath,
            fileExistsAtPath: fileExistsAtPath,
            createDirectoryAtPath: createDirectoryAtPath,
            contentsAtPath: contentsAtPath,
            writeStringToFile: writeStringToFile,
        )
    }
}
