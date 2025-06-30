import XCTest
@testable import FeedTracker

final class FeedEntryModelTests: XCTestCase {
    
    // MARK: - Waste Detection Tests
    
    func testFeedEntryWithPositiveVolume_ShouldNotBeIdentifiedAsWaste() {
        // Given: A feed entry with positive volume (normal feed)
        let feedEntry = FeedEntry(
            date: "6/29/2025",
            time: "10:30 AM",
            volume: 120,
            formulaType: "Breast milk",
            wasteAmount: 0
        )
        
        // When: Checking if it's waste
        let isWaste = feedEntry.isWaste
        
        // Then: Should not be identified as waste
        XCTAssertFalse(isWaste, "Feed entry with positive volume should not be identified as waste")
    }
    
    func testFeedEntryWithNegativeVolume_ShouldBeIdentifiedAsWaste() {
        // Given: A feed entry with negative volume (waste entry)
        let wasteEntry = FeedEntry(
            date: "6/29/2025",
            time: "11:00 AM",
            volume: -80,
            formulaType: "Similac 360",
            wasteAmount: 80
        )
        
        // When: Checking if it's waste
        let isWaste = wasteEntry.isWaste
        
        // Then: Should be identified as waste
        XCTAssertTrue(isWaste, "Feed entry with negative volume should be identified as waste")
    }
    
    func testFeedEntryWithZeroVolume_ShouldNotBeIdentifiedAsWaste() {
        // Given: A feed entry with zero volume
        let zeroEntry = FeedEntry(
            date: "6/29/2025",
            time: "12:00 PM",
            volume: 0,
            formulaType: "Breast milk",
            wasteAmount: 0
        )
        
        // When: Checking if it's waste
        let isWaste = zeroEntry.isWaste
        
        // Then: Should not be identified as waste (zero is not negative)
        XCTAssertFalse(isWaste, "Feed entry with zero volume should not be identified as waste")
    }
    
    // MARK: - Actual Volume Tests
    
    func testFeedEntryWithPositiveVolume_ShouldReturnSameActualVolume() {
        // Given: A normal feed entry with positive volume
        let feedEntry = FeedEntry(
            date: "6/29/2025",
            time: "2:00 PM",
            volume: 150,
            formulaType: "Emfamil Neuropro",
            wasteAmount: 0
        )
        
        // When: Getting actual volume
        let actualVolume = feedEntry.actualVolume
        
        // Then: Should return the same positive value
        XCTAssertEqual(actualVolume, 150, "Feed entry actual volume should match positive volume")
    }
    
    func testWasteEntryWithNegativeVolume_ShouldReturnAbsoluteValueAsActualVolume() {
        // Given: A waste entry with negative volume
        let wasteEntry = FeedEntry(
            date: "6/29/2025",
            time: "3:30 PM",
            volume: -75,
            formulaType: "Breast milk",
            wasteAmount: 75
        )
        
        // When: Getting actual volume
        let actualVolume = wasteEntry.actualVolume
        
        // Then: Should return absolute value (positive)
        XCTAssertEqual(actualVolume, 75, "Waste entry actual volume should be absolute value of negative volume")
    }
    
    // MARK: - Effective Volume Tests (For Calculations)
    
    func testFeedEntryEffectiveVolume_ShouldReturnPositiveVolumeForTotalCalculations() {
        // Given: A normal feed entry
        let feedEntry = FeedEntry(
            date: "6/29/2025",
            time: "4:00 PM",
            volume: 100,
            formulaType: "Breast milk",
            wasteAmount: 0
        )
        
        // When: Getting effective volume for calculations
        let effectiveVolume = feedEntry.effectiveVolume
        
        // Then: Should return positive volume
        XCTAssertEqual(effectiveVolume, 100, "Feed entry effective volume should be positive for adding to totals")
    }
    
    func testWasteEntryEffectiveVolume_ShouldReturnNegativeVolumeForTotalCalculations() {
        // Given: A waste entry
        let wasteEntry = FeedEntry(
            date: "6/29/2025",
            time: "5:00 PM",
            volume: -60,
            formulaType: "Similac 360",
            wasteAmount: 60
        )
        
        // When: Getting effective volume for calculations
        let effectiveVolume = wasteEntry.effectiveVolume
        
        // Then: Should return negative volume for subtracting from totals
        XCTAssertEqual(effectiveVolume, -60, "Waste entry effective volume should be negative for subtracting from totals")
    }
    
    // MARK: - Date Parsing Tests
    
    func testFeedEntryFullDate_ShouldParseValidDateAndTimeCorrectly() {
        // Given: A feed entry with valid date and time
        let feedEntry = FeedEntry(
            date: "6/29/2025",
            time: "10:30 AM",
            volume: 120,
            formulaType: "Breast milk",
            wasteAmount: 0
        )
        
        // When: Getting full date
        let fullDate = feedEntry.fullDate
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fullDate)
        
        // Then: Should parse date and time correctly
        XCTAssertEqual(components.year, 2025, "Year should be parsed correctly")
        XCTAssertEqual(components.month, 6, "Month should be parsed correctly")
        XCTAssertEqual(components.day, 29, "Day should be parsed correctly")
        XCTAssertEqual(components.hour, 10, "Hour should be parsed correctly")
        XCTAssertEqual(components.minute, 30, "Minute should be parsed correctly")
    }
    
    func testFeedEntryFullDate_ShouldReturnDistantPastForInvalidDate() {
        // Given: A feed entry with invalid date format
        let feedEntry = FeedEntry(
            date: "invalid-date",
            time: "invalid-time",
            volume: 120,
            formulaType: "Breast milk",
            wasteAmount: 0
        )
        
        // When: Getting full date
        let fullDate = feedEntry.fullDate
        
        // Then: Should return distant past for invalid dates
        XCTAssertEqual(fullDate, Date.distantPast, "Invalid date should return Date.distantPast")
    }
    
    // MARK: - Data Integrity Tests
    
    func testWasteEntry_ShouldHaveConsistentVolumeAndWasteAmount() {
        // Given: A waste entry where waste amount should match absolute volume
        let wasteEntry = FeedEntry(
            date: "6/29/2025",
            time: "6:00 PM",
            volume: -90,
            formulaType: "Breast milk",
            wasteAmount: 90
        )
        
        // When: Comparing actual volume and waste amount
        let actualVolume = wasteEntry.actualVolume
        let wasteAmount = wasteEntry.wasteAmount
        
        // Then: They should be equal for properly formed waste entries
        XCTAssertEqual(actualVolume, wasteAmount, "Waste entry actual volume should match waste amount")
        XCTAssertTrue(wasteEntry.isWaste, "Entry should be identified as waste")
    }
    
    func testFeedEntry_ShouldHaveZeroWasteAmount() {
        // Given: A normal feed entry
        let feedEntry = FeedEntry(
            date: "6/29/2025",
            time: "7:00 PM",
            volume: 130,
            formulaType: "Emfamil Neuropro",
            wasteAmount: 0
        )
        
        // When: Checking waste amount
        let wasteAmount = feedEntry.wasteAmount
        
        // Then: Should have zero waste amount
        XCTAssertEqual(wasteAmount, 0, "Normal feed entry should have zero waste amount")
        XCTAssertFalse(feedEntry.isWaste, "Entry should not be identified as waste")
    }
}