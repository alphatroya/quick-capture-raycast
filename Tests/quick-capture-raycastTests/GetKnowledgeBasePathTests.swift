import Foundation
@testable import quick_capture_raycast
import Testing

// MARK: - GetKnowledgeBasePathTests

@Suite("Get Knowledge Base Path Tests")
struct GetKnowledgeBasePathTests {
    @Test("Returns knowledge base path from home directory")
    func getKnowledgeBasePathFromHomeDirectory() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { path in
                path == "/Users/testuser/.config/raycast/knowledge-base" ? "/path/to/knowledge/base" : nil
            },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == "/path/to/knowledge/base", "Should return knowledge base path from config file in home directory")
    }

    @Test("Returns nil when config file does not exist")
    func getKnowledgeBasePathWhenConfigFileMissing() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { _ in nil },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == nil, "Should return nil when config file doesn't exist")
    }

    @Test("Returns nil when reading config file throws error")
    func getKnowledgeBasePathWhenReadingFails() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { _ in throw NSError(domain: "TestError", code: 1) },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == nil, "Should return nil when reading config file fails")
    }

    @Test("Trims whitespace and newlines from knowledge base path")
    func getKnowledgeBasePathTrimsWhitespace() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { _ in "  /path/to/knowledge/base  \n" },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == "/path/to/knowledge/base", "Should trim whitespace and newlines from knowledge base path")
    }

    @Test("Handles empty config file content")
    func getKnowledgeBasePathEmptyConfigFile() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { _ in "" },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == "", "Should handle empty config file content")
    }

    @Test("Handles config file with only whitespace")
    func getKnowledgeBasePathWhitespaceOnlyConfigFile() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/Users/testuser" },
            contentsAtPath: { _ in "   \n\t  " },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == "", "Should handle config file with only whitespace")
    }

    @Test("Constructs correct config file path from home directory")
    func getKnowledgeBasePathConstructsConfigPath() {
        let mockFileManager = FileWorker.mock(
            homeDirectoryPath: { "/custom/home/path" },
            contentsAtPath: { path in
                if path != "/custom/home/path/.config/raycast/knowledge-base" {
                    Issue.record("Should construct correct config file path")
                    return ""
                }
                return "/path/to/knowledge/base"
            },
        )

        let result = getKnowledgeBasePath(fileManager: mockFileManager)

        #expect(result == "/path/to/knowledge/base", "Should return knowledge base path")
    }
}
