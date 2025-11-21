#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Journal Entry
// @raycast.mode compact

// Optional parameters:
// @raycast.icon 📝
// @raycast.argument1 { "type": "text", "optional": true, "placeholder": "What's on your mind?" }
// @raycast.argument2 { "type": "text", "optional": true, "placeholder": "Tags (comma separated)" }

import AppKit
import Foundation
import LinkPresentation

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
    func fetchTitleAndFinalURL(from url: String) async throws -> (title: String, finalURL: String)
    func extractTitle(from html: String) throws -> String
    func decodeHTMLEntities(_ string: String) -> String
}

extension NetworkFetcherProtocol {
    func extractTitle(from html: String) throws -> String {
        let pattern = #"<title[^>]*>(.*?)</title\s*>"#
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            throw TitleError.missingTitle
        }

        let titleMatch = String(html[range])
        let titleContent = titleMatch.replacingOccurrences(of: #"<title[^>]*>|</title\s*>"#, with: "", options: .regularExpression)
        let decodedTitle = decodeHTMLEntities(titleContent)
        return decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func decodeHTMLEntities(_ string: String) -> String {
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
    private let maxRedirects = 10

    // MARK: Lifecycle

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Functions

    func fetchTitleAndFinalURL(from url: String) async throws -> (title: String, finalURL: String) {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        guard url.scheme == "http" || url.scheme == "https" else {
            throw URLError(.unsupportedURL)
        }

        let metadataProvider = LPMetadataProvider()
        let metadata = try await metadataProvider.startFetchingMetadata(for: url)
        return (title: metadata.title ?? "", finalURL: (metadata.url ?? url).absoluteString)
    }

    private func followRedirects(from url: URL, redirectCount: Int = 0) async throws -> URL {
        guard redirectCount < maxRedirects else {
            throw URLError(.cannotFindHost)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return url
        }

        switch httpResponse.statusCode {
        case 301, 302, 307, 308:
            guard let location = httpResponse.value(forHTTPHeaderField: "Location"),
                  let redirectURL = URL(string: location, relativeTo: url)
            else {
                return url
            }

            return try await followRedirects(from: redirectURL, redirectCount: redirectCount + 1)

        default:
            return url
        }
    }
}

// MARK: - SystemNetworkFetcher

enum SystemNetworkFetcher {
    static let system: NetworkFetcherProtocol = URLSessionNetworkFetcher()
}

func markdownURLIfNeeded(
    _ url: String,
    titleFetcher: NetworkFetcherProtocol = SystemNetworkFetcher.system,
) async -> String {
    guard isURL(url) else { return url }

    let finalTitle: String
    let finalURL: String
    do {
        let (title, url) = try await titleFetcher.fetchTitleAndFinalURL(from: url)
        finalTitle = title
        finalURL = url
    } catch {
        return url
    }

    guard !finalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return url
    }

    return "[\(finalTitle)](\(finalURL))"
}

func parseTags(from input: String) -> String? {
    let components = input.components(separatedBy: ",")
    let tags = components.map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .map { tag in
            if tag.contains(" ") {
                "#[[\(tag)]]"
            } else {
                "#\(tag)"
            }
        }

    return tags.isEmpty ? nil : tags.joined(separator: " ")
}

func getInputFromArgumentsOrClipboard(
    arguments: [String] = CommandLine.arguments,
    pasteboard: PasteboardReader = .system,
) throws -> (input: String, tags: String?) {
    let input: String
    if arguments.count > 1, !arguments[1].isEmpty {
        input = arguments[1]
    } else if let clipboardContent = getClipboardContent(pasteboard: pasteboard), !clipboardContent.isEmpty {
        input = clipboardContent
    } else {
        throw InputError.noInputAvailable
    }

    let tags = arguments.count > 2 ? parseTags(from: arguments[2]) : nil
    return (input, tags)
}

// MARK: - InputError

enum InputError: Error {
    case noInputAvailable
}

// MARK: - App

enum App {
    static func main() async {
        guard let (input, tags) = try? getInputFromArgumentsOrClipboard() else {
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
            let tagsString = tags.map { " \($0)" } ?? ""
            let defaultTag = " #[[raycast quick capture]]"
            let lineToAppend = "- TODO **\(timeString)** \(processedInput)\(tagsString)\(defaultTag)\n"

            try appendToJournalFile(at: filePath, content: lineToAppend)

            print("Successfully added to journal: \(filePath)")
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}

await App.main()
