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

// MARK: - FileHandleProtocol

protocol FileHandleProtocol {
    func seekToEndOfFile() -> UInt64
    func write(_ data: Data)
    func closeFile()
}

// MARK: - FileHandle + FileHandleProtocol

extension FileHandle: FileHandleProtocol {}

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

    var fileHandleForWritingToPath: @Sendable (String) throws -> FileHandleProtocol = { path in
        try FileHandle(forWritingTo: URL(fileURLWithPath: path))
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
        let needsNewline = !currentContent.isEmpty && !currentContent.hasSuffix("\n")
        let contentToAppend = needsNewline ? "\n" + content : content

        let fileHandle = try fileManager.fileHandleForWritingToPath(filePath)
        _ = fileHandle.seekToEndOfFile()
        fileHandle.write(contentToAppend.data(using: .utf8)!)
        fileHandle.closeFile()
    } else {
        try fileManager.writeStringToFile(content, filePath, true, .utf8)
    }
}

func isURL(_ string: String) -> Bool {
    guard let url = URL(string: string) else { return false }

    return url.scheme == "http" || url.scheme == "https"
}

// MARK: - NetworkFetcherProtocol

protocol NetworkFetcherProtocol: Sendable {
    func fetchTitle(from url: String) async throws -> String
}

// MARK: - TitleError

enum TitleError: Error, Sendable {
    case missingTitle
    case invalidHTML
    case networkError(Error)
}

// MARK: - URLSessionNetworkFetcher

struct URLSessionNetworkFetcher: NetworkFetcherProtocol, Sendable {
    // MARK: Properties

    private let session: URLSession

    // MARK: Lifecycle

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Functions

    func fetchTitle(from url: String) async throws -> String {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        guard url.scheme == "http" || url.scheme == "https" else {
            throw URLError(.unsupportedURL)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard httpResponse.statusCode == 200 else {
            throw URLError(.resourceUnavailable)
        }

        let html = String(data: data, encoding: .utf8) ?? ""
        return try extractTitle(from: html)
    }

    private func extractTitle(from html: String) throws -> String {
        let pattern = #"<title[^>]*>(.*?)</title\s*>"#
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            throw TitleError.missingTitle
        }

        let titleMatch = String(html[range])
        let titleContent = titleMatch.replacingOccurrences(of: #"<title[^>]*>|</title\s*>"#, with: "", options: .regularExpression)
        let decodedTitle = decodeHTMLEntities(titleContent)
        return decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }

        return string
    }
}

// MARK: - SystemNetworkFetcher

enum SystemNetworkFetcher {
    static let system: NetworkFetcherProtocol = URLSessionNetworkFetcher()
}

func getTitle(for url: String, networkFetcher: NetworkFetcherProtocol = SystemNetworkFetcher.system) async throws -> String {
    try await networkFetcher.fetchTitle(from: url)
}

func markdownURLIfNeeded(
    _ url: String,
    titleFetcher: NetworkFetcherProtocol = SystemNetworkFetcher.system,
) async -> String {
    guard isURL(url) else { return url }

    let finalTitle: String
    do {
        finalTitle = try await getTitle(for: url, networkFetcher: titleFetcher)
    } catch {
        return url
    }

    guard !finalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return url
    }

    return "[\(finalTitle)](\(url))"
}

func getInputFromArgumentsOrClipboard(
    arguments: [String] = CommandLine.arguments,
    pasteboard: PasteboardReader = .system,
) throws -> String {
    if arguments.count > 1, !arguments[1].isEmpty {
        return arguments[1]
    } else if let clipboardContent = getClipboardContent(pasteboard: pasteboard), !clipboardContent.isEmpty {
        return clipboardContent
    } else {
        throw InputError.noInputAvailable
    }
}

// MARK: - InputError

enum InputError: Error {
    case noInputAvailable
}

@MainActor
func main() async {
    guard let input = try? getInputFromArgumentsOrClipboard() else {
        print("Error: No input provided and clipboard is empty")
        exit(1)
    }
    guard let knowledgeBase = getKnowledgeBasePath() else {
        print("Error: Could not determine knowledge base path")
        exit(1)
    }

    let processedInput = await markdownURLIfNeeded(input)

    let today = formatDate("yyyy_MM_dd")
    let fileName = "\(today).md"
    let journalsPath = (knowledgeBase as NSString).appendingPathComponent("journals")
    let filePath = (journalsPath as NSString).appendingPathComponent(fileName)

    do {
        try ensureDirectoryExists(at: journalsPath)

        let timeString = formatDate("HH:mm")
        let lineToAppend = "- TODO **\(timeString)** \(processedInput)\n"

        try appendToJournalFile(at: filePath, content: lineToAppend)

        print("Successfully added to journal: \(filePath)")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

await main()
