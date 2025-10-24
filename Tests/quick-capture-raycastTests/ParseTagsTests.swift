import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Parse Tags Tests")
struct ParseTagsTests {
    @Test(arguments: [
        (input: "work", expected: "#work", description: "Parses single tag"),
        (
            input: "work,personal,urgent",
            expected: "#work #personal #urgent",
            description: "Parses multiple tags separated by commas",
        ),
        (input: "  work  ,  personal  ,  urgent  ", expected: "#work #personal #urgent", description: "Trims whitespace from tags"),
        (input: "work,,personal,,urgent", expected: "#work #personal #urgent", description: "Handles empty tags"),
        (input: "work,   ,personal,   ,urgent", expected: "#work #personal #urgent", description: "Handles whitespace-only tags"),
        (input: "", expected: nil as String?, description: "Handles empty string input"),
        (input: "   ", expected: nil as String?, description: "Handles whitespace-only input"),
        (input: ",", expected: nil as String?, description: "Handles single comma input"),
        (input: "work,,,personal", expected: "#work #personal", description: "Handles multiple consecutive commas"),
        (
            input: "work,personal-urgent,project_alpha",
            expected: "#work #personal-urgent #project_alpha",
            description: "Handles tags with special characters",
        ),
        (input: "task1,priority2,version3", expected: "#task1 #priority2 #version3", description: "Handles tags with numbers"),
        (input: "Work,PERSONAL,Urgent", expected: "#Work #PERSONAL #Urgent", description: "Handles mixed case tags"),
        (
            input: "tags with spaces,another tag",
            expected: "#[[tags with spaces]] #[[another tag]]",
            description: "Handles tags with spaces using double brackets",
        ),
        (
            input: "  spaced tag  ,  another spaced tag  ",
            expected: "#[[spaced tag]] #[[another spaced tag]]",
            description: "Trims and wraps spaced tags with double brackets",
        ),
        (
            input: "normal,spaced tag,mixed",
            expected: "#normal #[[spaced tag]] #mixed",
            description: "Handles mix of normal and spaced tags",
        ),
    ])
    func parse(input: String, expected: String?, description: Comment) {
        let result = parseTags(from: input)
        #expect(result == expected, description)
    }
}
