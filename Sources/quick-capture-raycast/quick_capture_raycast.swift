#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Journal Entry
// @raycast.mode compact

// Optional parameters:
// @raycast.icon 📝
// @raycast.argument1 { "type": "text", "placeholder": "What's on your mind?" }

import Foundation

func main() {
    let arguments = CommandLine.arguments

    guard arguments.count > 1 else {
        print("Error: No input provided")
        exit(1)
    }
    let input = arguments[1]

    let knowledgeBase = "/Volumes/Logseq"

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy_MM_dd"
    let today = formatter.string(from: Date())
    let fileName = "\(today).md"
    let journalsPath = (knowledgeBase as NSString).appendingPathComponent("journals")
    let filePath = (journalsPath as NSString).appendingPathComponent(fileName)

    do {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: journalsPath) {
            try fileManager.createDirectory(atPath: journalsPath, withIntermediateDirectories: true, attributes: nil)
        }

        let timestamp = DateFormatter()
        timestamp.dateFormat = "HH:mm"
        let timeString = timestamp.string(from: Date())

        let lineToAppend = "- **\(timeString)** \(input)\n"

        if fileManager.fileExists(atPath: filePath) {
            let currentContent = try String(contentsOfFile: filePath, encoding: .utf8)
            let needsNewline = !currentContent.hasSuffix("\n")
            let contentToAppend = needsNewline ? "\n" + lineToAppend : lineToAppend

            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
            fileHandle.seekToEndOfFile()
            fileHandle.write(contentToAppend.data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            try lineToAppend.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        print("Successfully added to journal: \(filePath)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

main()
