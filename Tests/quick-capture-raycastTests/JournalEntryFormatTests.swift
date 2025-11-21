import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Journal Entry Format Tests")
struct JournalEntryFormatTests {
    @Test("Journal entry includes default raycast quick capture tag without user tags")
    func includesDefaultTagWithoutUserTags() {
        let content = "Test content"
        let fixedDate = Date(timeIntervalSince1970: 1700000000) // 2023-11-14 22:13:20 UTC
        let result = formatJournalEntry(content: content, userTags: nil, date: fixedDate)
        
        #expect(result == "- TODO **22:13** Test content #[[raycast quick capture]]\n")
    }
    
    @Test("Journal entry includes default raycast quick capture tag with user tags")
    func includesDefaultTagWithUserTags() {
        let content = "Test content"
        let userTags = "#work #personal"
        let fixedDate = Date(timeIntervalSince1970: 1700000000)
        let result = formatJournalEntry(content: content, userTags: userTags, date: fixedDate)
        
        #expect(result == "- TODO **22:13** Test content #work #personal #[[raycast quick capture]]\n")
    }
    
    @Test("Journal entry with URL includes default tag")
    func includesDefaultTagWithURL() {
        let content = "[GitHub](https://github.com)"
        let fixedDate = Date(timeIntervalSince1970: 1700000000)
        let result = formatJournalEntry(content: content, userTags: nil, date: fixedDate)
        
        #expect(result == "- TODO **22:13** [GitHub](https://github.com) #[[raycast quick capture]]\n")
    }
}
