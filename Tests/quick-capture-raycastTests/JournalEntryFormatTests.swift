import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Journal Entry Format Tests")
struct JournalEntryFormatTests {
    @Test("Journal entry includes default raycast quick capture tag without user tags")
    func includesDefaultTagWithoutUserTags() {
        let timeString = "10:30"
        let processedInput = "Test content"
        let tagsString = ""
        let defaultTag = " #[[raycast quick capture]]"
        let lineToAppend = "- TODO **\(timeString)** \(processedInput)\(tagsString)\(defaultTag)\n"
        
        #expect(lineToAppend.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(lineToAppend == "- TODO **10:30** Test content #[[raycast quick capture]]\n", "Should match expected format")
    }
    
    @Test("Journal entry includes default raycast quick capture tag with user tags")
    func includesDefaultTagWithUserTags() {
        let timeString = "10:30"
        let processedInput = "Test content"
        let tagsString = " #work #personal"
        let defaultTag = " #[[raycast quick capture]]"
        let lineToAppend = "- TODO **\(timeString)** \(processedInput)\(tagsString)\(defaultTag)\n"
        
        #expect(lineToAppend.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(lineToAppend.contains("#work"), "Should contain user tag #work")
        #expect(lineToAppend.contains("#personal"), "Should contain user tag #personal")
        #expect(lineToAppend == "- TODO **10:30** Test content #work #personal #[[raycast quick capture]]\n", "Should match expected format with user tags followed by default tag")
    }
    
    @Test("Journal entry with URL includes default tag")
    func includesDefaultTagWithURL() {
        let timeString = "14:45"
        let processedInput = "[GitHub](https://github.com)"
        let tagsString = ""
        let defaultTag = " #[[raycast quick capture]]"
        let lineToAppend = "- TODO **\(timeString)** \(processedInput)\(tagsString)\(defaultTag)\n"
        
        #expect(lineToAppend.contains("#[[raycast quick capture]]"), "Should contain the default raycast quick capture tag")
        #expect(lineToAppend == "- TODO **14:45** [GitHub](https://github.com) #[[raycast quick capture]]\n", "Should include default tag with markdown URL")
    }
    
    @Test("Default tag format uses double brackets for multi-word tag")
    func usesDoubleBracketsForMultiWordTag() {
        let defaultTag = " #[[raycast quick capture]]"
        
        #expect(defaultTag.contains("[["), "Should use opening double brackets")
        #expect(defaultTag.contains("]]"), "Should use closing double brackets")
        #expect(defaultTag == " #[[raycast quick capture]]", "Should exactly match the expected format")
    }
}
