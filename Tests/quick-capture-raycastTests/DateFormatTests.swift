import Foundation
@testable import quick_capture_raycast
import Testing

@Suite("Date Format Tests")
struct DateFormatTests {
    @Test("Formats date with year_month_day pattern")
    func formatDateWithYearMonthDay() {
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // January 1, 2022 00:00:00 UTC
        let result = formatDate("yyyy_MM_dd", date: testDate)

        #expect(result == "2022_01_01", "Should format date as year_month_day")
    }

    @Test("Formats date with hour_minute pattern")
    func formatDateWithHourMinute() {
        let testDate = Date(timeIntervalSince1970: 1_640_995_200 + 3661) // January 1, 2022 01:01:01 UTC
        let result = formatDate("HH:mm", date: testDate)

        // The result depends on the local timezone, so we just verify it's in the correct format
        #expect(result.count == 5, "Should return 5 characters for HH:mm format")
        #expect(result.contains(":"), "Should contain colon as separator")
        let components = result.components(separatedBy: ":")
        #expect(components.count == 2, "Should have hour and minute components")
        #expect(components[0].count == 2, "Hour should be 2 digits")
        #expect(components[1].count == 2, "Minute should be 2 digits")
    }

    @Test("Formats date with custom pattern")
    func formatDateWithCustomPattern() {
        let testDate = Date(timeIntervalSince1970: 1_640_995_200) // January 1, 2022 00:00:00 UTC
        let result = formatDate("yyyy-MM-dd HH:mm:ss", date: testDate)

        // Verify the format is correct (timezone may vary)
        #expect(result.hasPrefix("2022-01-01 "), "Should start with correct date")
        #expect(result.count == 19, "Should return 19 characters for yyyy-MM-dd HH:mm:ss format")
        let timeComponents = result.components(separatedBy: " ")[1].components(separatedBy: ":")
        #expect(timeComponents.count == 3, "Should have hour, minute, and second components")
    }

    @Test("Formats date with month name")
    func formatDateWithMonthName() {
        let testDate = Date(timeIntervalSince1970: 1_643_673_600) // February 1, 2022 00:00:00 UTC
        let result = formatDate("MMMM dd, yyyy", date: testDate)

        #expect(result == "February 01, 2022", "Should format date with month name")
    }

    @Test("Works with current date")
    func formatDateWithCurrentDate() {
        let result = formatDate("yyyy_MM_dd")

        // Should return a string in the expected format
        #expect(result.count == 10, "Should return 10 characters for yyyy_MM_dd format")
        #expect(result.contains("_"), "Should contain underscores as separators")

        // Should be a valid date format
        let components = result.components(separatedBy: "_")
        #expect(components.count == 3, "Should have year, month, and day components")
        #expect(components[0].count == 4, "Year should be 4 digits")
        #expect(components[1].count == 2, "Month should be 2 digits")
        #expect(components[2].count == 2, "Day should be 2 digits")
    }
}
