#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Quick capture
// @raycast.mode compact

// Optional parameters:
// @raycast.icon 🤖
// @raycast.argument1 { "type": "text", "placeholder": "from city" }

import Foundation

func main() {
    let arguments = CommandLine.arguments

    guard arguments.count > 1 else {
        print("Error: No input provided")
        exit(1)
    }
    let input = arguments[1]

    guard let homeDir = ProcessInfo.processInfo.environment["HOME"] else {
        print("Error: HOME environment variable not set")
        exit(1)
    }
    let knowledgeBase = (homeDir as NSString).appendingPathComponent("Downloads")

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
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
            fileHandle.seekToEndOfFile()
            fileHandle.write(lineToAppend.data(using: .utf8)!)
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
