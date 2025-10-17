#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Journal Entry
// @raycast.mode compact

// Optional parameters:
// @raycast.icon 📝
// @raycast.argument1 { "type": "text", "optional": true, "placeholder": "What's on your mind?" }

import AppKit
import Foundation

// MARK: - FileWorker

struct FileWorker: Sendable {
    // MARK: Static Properties

    static let system: FileWorker = .init()

    // MARK: Properties

    var homeDirectoryPath: @Sendable () -> String = {
        ProcessInfo.processInfo.environment["HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.path
    }

    var fileExistsAtPath: @Sendable (String) -> Bool = {
        FileManager.default.fileExists(atPath: $0)
    }

    var createDirectoryAtPath: @Sendable (String, Bool, [FileAttributeKey: Any]?) throws
        -> Void = { path, createIntermediates, attributes in
            try FileManager.default.createDirectory(
                atPath: path,
                withIntermediateDirectories: createIntermediates,
                attributes: attributes,
            )
        }

    var contentsAtPath: @Sendable (String) throws -> String? = { path in
        try String(contentsOfFile: path, encoding: .utf8)
    }

    var writeStringToFile: @Sendable (String, String, Bool, String.Encoding) throws -> Void = { content, path, atomically, encoding in
        try content.write(toFile: path, atomically: atomically, encoding: encoding)
    }
}

// MARK: - PasteboardReader

struct PasteboardReader: Sendable {
    // MARK: Static Properties

    static let system: PasteboardReader = .init {
        NSPasteboard.general.string(forType: .string)
    }

    // MARK: Properties

    var read: @Sendable () -> String?
}

func getClipboardContent(pasteboard: PasteboardReader = .system) -> String? {
    pasteboard.read()
}

func formatDate(_ format: String, date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
}

func getKnowledgeBasePath(fileManager: FileWorker = .system) -> String? {
    let homePath = fileManager.homeDirectoryPath()
    let configPath = (homePath as NSString).appendingPathComponent(".config/raycast/knowledge-base")

    do {
        return try fileManager.contentsAtPath(configPath)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        print("Warning: Could not read knowledge base path from \(configPath): \(error)")
        return nil
    }
}

func ensureDirectoryExists(at path: String, fileManager: FileWorker = .system) throws {
    if !fileManager.fileExistsAtPath(path) {
        try fileManager.createDirectoryAtPath(path, true, nil)
    }
}

func appendToJournalFile(at filePath: String, content: String, fileManager: FileWorker = .system) throws {
    if fileManager.fileExistsAtPath(filePath) {
        let currentContent = try fileManager.contentsAtPath(filePath) ?? ""
        let needsNewline = !currentContent.hasSuffix("\n")
        let contentToAppend = needsNewline ? "\n" + content : content

        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentToAppend.data(using: .utf8)!)
        fileHandle.closeFile()
    } else {
        try fileManager.writeStringToFile(content, filePath, true, .utf8)
    }
}

func main() {
    let arguments = CommandLine.arguments
    var input: String

    if arguments.count > 1, !arguments[1].isEmpty {
        input = arguments[1]
    } else if let clipboardContent = getClipboardContent(), !clipboardContent.isEmpty {
        input = clipboardContent
    } else {
        print("Error: No input provided and clipboard is empty")
        exit(1)
    }

    guard let knowledgeBase = getKnowledgeBasePath() else {
        print("Error: Could not determine knowledge base path")
        exit(1)
    }

    let today = formatDate("yyyy_MM_dd")
    let fileName = "\(today).md"
    let journalsPath = (knowledgeBase as NSString).appendingPathComponent("journals")
    let filePath = (journalsPath as NSString).appendingPathComponent(fileName)

    do {
        try ensureDirectoryExists(at: journalsPath)

        let timeString = formatDate("HH:mm")
        let lineToAppend = "- TODO **\(timeString)** \(input)\n"

        try appendToJournalFile(at: filePath, content: lineToAppend)

        print("Successfully added to journal: \(filePath)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

main()
