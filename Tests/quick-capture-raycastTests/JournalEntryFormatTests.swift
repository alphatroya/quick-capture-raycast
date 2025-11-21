import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Journal Entry Format Tests")
struct JournalEntryFormatTests {
    static let defaultTag = " #[[raycast quick capture]]"
    
    @Test("Journal entry includes default raycast quick capture tag without user tags")
    func includesDefaultTagWithoutUserTags() {
        let content = "Test content"
        let fixedDate = Date(timeIntervalSince1970: 1700000000) // 2023-11-14 22:13:20 UTC
        let result = formatJournalEntry(content: content, userTags: nil, date: fixedDate)
        
        #expect(result.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(result.contains("Test content"), "Should contain the content")
        #expect(result.hasPrefix("- TODO **"), "Should start with TODO marker")
        #expect(result.hasSuffix("\(Self.defaultTag)\n"), "Should end with default tag and newline")
    }
    
    @Test("Journal entry includes default raycast quick capture tag with user tags")
    func includesDefaultTagWithUserTags() {
        let content = "Test content"
        let userTags = "#work #personal"
        let fixedDate = Date(timeIntervalSince1970: 1700000000)
        let result = formatJournalEntry(content: content, userTags: userTags, date: fixedDate)
        
        #expect(result.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(result.contains("#work"), "Should contain user tag #work")
        #expect(result.contains("#personal"), "Should contain user tag #personal")
        #expect(result.contains("Test content"), "Should contain the content")
        // Verify order: content, then user tags, then default tag
        let contentIndex = result.range(of: "Test content")!.upperBound
        let workIndex = result.range(of: "#work")!.lowerBound
        let defaultIndex = result.range(of: "#[[raycast quick capture]]")!.lowerBound
        #expect(contentIndex < workIndex, "Content should come before user tags")
        #expect(workIndex < defaultIndex, "User tags should come before default tag")
    }
    
    @Test("Journal entry with URL includes default tag")
    func includesDefaultTagWithURL() {
        let content = "[GitHub](https://github.com)"
        let fixedDate = Date(timeIntervalSince1970: 1700000000)
        let result = formatJournalEntry(content: content, userTags: nil, date: fixedDate)
        
        #expect(result.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(result.contains("[GitHub](https://github.com)"), "Should contain the markdown URL")
    }
    
    @Test("Default tag format uses double brackets for multi-word tag")
    func usesDoubleBracketsForMultiWordTag() {
        #expect(Self.defaultTag.contains("[["), "Should use opening double brackets")
        #expect(Self.defaultTag.contains("]]"), "Should use closing double brackets")
        #expect(Self.defaultTag == " #[[raycast quick capture]]", "Should exactly match the expected format")
    }
    
    @Test("Journal entry uses current date when not specified")
    func usesCurrentDateWhenNotSpecified() {
        let content = "Test content"
        let result = formatJournalEntry(content: content, userTags: nil)
        
        // Should contain a time in HH:mm format
        let timePattern = #"\*\*\d{2}:\d{2}\*\*"#
        #expect(result.range(of: timePattern, options: .regularExpression) != nil, "Should contain time in HH:mm format")
    }
}
