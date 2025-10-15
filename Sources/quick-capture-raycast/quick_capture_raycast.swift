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

func getClipboardContent() -> String? {
    let pasteboard = NSPasteboard.general
    return pasteboard.string(forType: .string)
}

func formatDate(_ format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: Date())
}

func getKnowledgeBasePath() -> String? {
    let homePath = ProcessInfo.processInfo.environment["HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.path
    let configPath = (homePath as NSString).appendingPathComponent(".config/raycast/knowledge-base")

    do {
        return try String(contentsOfFile: configPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        print("Warning: Could not read knowledge base path from \(configPath): \(error)")
        return nil
    }
}

func ensureDirectoryExists(at path: String) throws {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path) {
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
}

func appendToJournalFile(at filePath: String, content: String) throws {
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: filePath) {
        let currentContent = try String(contentsOfFile: filePath, encoding: .utf8)
        let needsNewline = !currentContent.hasSuffix("\n")
        let contentToAppend = needsNewline ? "\n" + content : content

        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentToAppend.data(using: .utf8)!)
        fileHandle.closeFile()
    } else {
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
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
        let lineToAppend = "- **\(timeString)** \(input)\n"

        try appendToJournalFile(at: filePath, content: lineToAppend)

        print("Successfully added to journal: \(filePath)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

main()
