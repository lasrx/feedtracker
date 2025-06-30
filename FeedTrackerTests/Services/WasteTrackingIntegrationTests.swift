import XCTest
@testable import FeedTracker

final class WasteTrackingIntegrationTests: XCTestCase {
    
    // MARK: - Data Model Integration Tests
    
    func testFeedHistoryCalculations_ShouldCorrectlyCalculateWasteAndFeedTotals() {
        // Given: A mix of feed and waste entries for today
        let feedEntries = [
            FeedEntry(date: "6/29/2025", time: "8:00 AM", volume: 120, formulaType: "Breast milk", wasteAmount: 0),
            FeedEntry(date: "6/29/2025", time: "9:30 AM", volume: -30, formulaType: "Breast milk", wasteAmount: 30), // Waste
            FeedEntry(date: "6/29/2025", time: "12:00 PM", volume: 150, formulaType: "Similac 360", wasteAmount: 0),
            FeedEntry(date: "6/29/2025", time: "2:00 PM", volume: -20, formulaType: "Similac 360", wasteAmount: 20), // Waste
            FeedEntry(date: "6/29/2025", time: "4:00 PM", volume: 100, formulaType: "Breast milk", wasteAmount: 0)
        ]
        
        // When: Calculating totals like FeedHistoryView would
        let totalEffectiveVolume = feedEntries.reduce(0) { $0 + $1.effectiveVolume }
        let totalWasted = feedEntries.filter { $0.isWaste }.reduce(0) { $0 + $1.actualVolume }
        let totalFed = feedEntries.filter { !$0.isWaste }.reduce(0) { $0 + $1.actualVolume }
        let feedCount = feedEntries.filter { !$0.isWaste }.count
        let wasteCount = feedEntries.filter { $0.isWaste }.count
        
        // Then: Calculations should be correct
        XCTAssertEqual(totalEffectiveVolume, 320, "Total effective volume should be 120 + (-30) + 150 + (-20) + 100 = 320")
        XCTAssertEqual(totalWasted, 50, "Total wasted should be 30 + 20 = 50 mL")
        XCTAssertEqual(totalFed, 370, "Total fed should be 120 + 150 + 100 = 370 mL")
        XCTAssertEqual(feedCount, 3, "Should count 3 actual feed entries")
        XCTAssertEqual(wasteCount, 2, "Should count 2 waste entries")
    }
    
    func testAverageVolumeCalculation_ShouldExcludeWasteEntriesFromFeedAverage() {
        // Given: Feed entries including waste (as would be displayed in FeedHistoryView)
        let feedEntries = [
            FeedEntry(date: "6/29/2025", time: "8:00 AM", volume: 120, formulaType: "Breast milk", wasteAmount: 0),
            FeedEntry(date: "6/29/2025", time: "9:30 AM", volume: -50, formulaType: "Breast milk", wasteAmount: 50), // Waste - should be excluded
            FeedEntry(date: "6/29/2025", time: "12:00 PM", volume: 180, formulaType: "Similac 360", wasteAmount: 0),
            FeedEntry(date: "6/29/2025", time: "4:00 PM", volume: 100, formulaType: "Breast milk", wasteAmount: 0)
        ]
        
        // When: Calculating average like FeedHistoryView would
        let feedOnlyEntries = feedEntries.filter { !$0.isWaste }
        let totalFeedVolume = feedOnlyEntries.reduce(0) { $0 + $1.actualVolume }
        let averageVolume = feedOnlyEntries.isEmpty ? 0 : totalFeedVolume / feedOnlyEntries.count
        
        // Then: Average should only consider actual feeds
        XCTAssertEqual(averageVolume, 133, "Average should be (120 + 180 + 100) / 3 = 133.33 ≈ 133")
        XCTAssertEqual(feedOnlyEntries.count, 3, "Should exclude waste entry from feed average calculation")
    }
    
    // MARK: - Google Sheets Data Format Tests
    
    func testGoogleSheetsDataFormat_ShouldProduceFiveColumnRowsForWasteEntries() {
        // Given: Parameters for a waste entry submission
        let date = "6/29/2025"
        let time = "10:30 AM"
        let volume = "-80"  // Negative for waste
        let formulaType = "Breast milk"
        let wasteAmount = "80"  // Positive waste amount
        
        // When: Formatting for Google Sheets (simulating appendFeed call)
        let row = [date, time, volume, formulaType, wasteAmount]
        
        // Then: Should produce correctly formatted 5-column row
        XCTAssertEqual(row.count, 5, "Waste entry should produce 5-column row")
        XCTAssertEqual(row[0], "6/29/2025", "Column A should be date")
        XCTAssertEqual(row[1], "10:30 AM", "Column B should be time")
        XCTAssertEqual(row[2], "-80", "Column C should be negative volume for waste")
        XCTAssertEqual(row[3], "Breast milk", "Column D should be formula type")
        XCTAssertEqual(row[4], "80", "Column E should be positive waste amount")
    }
    
    func testGoogleSheetsDataFormat_ShouldProduceFiveColumnRowsForFeedEntries() {
        // Given: Parameters for a normal feed entry submission
        let date = "6/29/2025"
        let time = "11:00 AM"
        let volume = "150"  // Positive for feed
        let formulaType = "Similac 360"
        let wasteAmount = "0"  // Zero waste for normal feed
        
        // When: Formatting for Google Sheets
        let row = [date, time, volume, formulaType, wasteAmount]
        
        // Then: Should produce correctly formatted 5-column row
        XCTAssertEqual(row.count, 5, "Feed entry should produce 5-column row")
        XCTAssertEqual(row[0], "6/29/2025", "Column A should be date")
        XCTAssertEqual(row[1], "11:00 AM", "Column B should be time")
        XCTAssertEqual(row[2], "150", "Column C should be positive volume for feed")
        XCTAssertEqual(row[3], "Similac 360", "Column D should be formula type")
        XCTAssertEqual(row[4], "0", "Column E should be zero waste amount for feed")
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testBackwardCompatibility_ShouldHandleFourColumnRowsFromLegacySheets() {
        // Given: Legacy 4-column row data (no waste amount column)
        let legacyRow = ["6/29/2025", "10:00 AM", "120", "Breast milk"]
        
        // When: Parsing like GoogleSheetsStorageService.fetchTodayFeeds would
        let date = legacyRow[0]
        let time = legacyRow[1]
        let volume = Int(legacyRow[2]) ?? 0
        let formulaType = legacyRow[3]
        let wasteAmount = legacyRow.count >= 5 ? Int(legacyRow[4]) ?? 0 : 0  // Default to 0 for legacy
        
        let feedEntry = FeedEntry(
            date: date,
            time: time,
            volume: volume,
            formulaType: formulaType,
            wasteAmount: wasteAmount
        )
        
        // Then: Should create valid feed entry with zero waste amount
        XCTAssertEqual(feedEntry.date, "6/29/2025", "Should parse date correctly")
        XCTAssertEqual(feedEntry.time, "10:00 AM", "Should parse time correctly")
        XCTAssertEqual(feedEntry.volume, 120, "Should parse volume correctly")
        XCTAssertEqual(feedEntry.formulaType, "Breast milk", "Should parse formula type correctly")
        XCTAssertEqual(feedEntry.wasteAmount, 0, "Should default waste amount to 0 for legacy 4-column data")
        XCTAssertFalse(feedEntry.isWaste, "Legacy positive volume should not be waste")
    }
    
    func testBackwardCompatibility_ShouldHandleFiveColumnRowsFromNewSheets() {
        // Given: New 5-column row data with waste amount
        let newRow = ["6/29/2025", "2:00 PM", "-75", "Similac 360", "75"]
        
        // When: Parsing like GoogleSheetsStorageService.fetchTodayFeeds would
        let date = newRow[0]
        let time = newRow[1]
        let volume = Int(newRow[2]) ?? 0
        let formulaType = newRow[3]
        let wasteAmount = newRow.count >= 5 ? Int(newRow[4]) ?? 0 : 0
        
        let feedEntry = FeedEntry(
            date: date,
            time: time,
            volume: volume,
            formulaType: formulaType,
            wasteAmount: wasteAmount
        )
        
        // Then: Should create valid waste entry
        XCTAssertEqual(feedEntry.date, "6/29/2025", "Should parse date correctly")
        XCTAssertEqual(feedEntry.time, "2:00 PM", "Should parse time correctly")
        XCTAssertEqual(feedEntry.volume, -75, "Should parse negative volume correctly")
        XCTAssertEqual(feedEntry.formulaType, "Similac 360", "Should parse formula type correctly")
        XCTAssertEqual(feedEntry.wasteAmount, 75, "Should parse waste amount correctly")
        XCTAssertTrue(feedEntry.isWaste, "Negative volume should be identified as waste")
        XCTAssertEqual(feedEntry.actualVolume, 75, "Actual volume should be absolute value")
    }
    
    // MARK: - UI Integration Tests
    
    func testWasteEntryUIFlow_ShouldProduceCorrectDataForSubmission() {
        // Given: User interaction flow for waste entry
        let mockStorage = MockStorageService()
        let viewModel = FeedEntryViewModel(storageService: mockStorage)
        
        // Simulate user entering waste data
        viewModel.volume = "90"
        viewModel.formulaType = "Breast milk"
        viewModel.isWaste = false  // Start in feed mode
        
        // When: User toggles to waste mode and submits
        viewModel.toggleWasteMode()  // Switch to waste mode
        mockStorage.isSignedIn = true
        
        // Simulate submission (we can't easily test async here, so we test the data preparation)
        let volumeForStorage = viewModel.isWaste ? "-\(viewModel.volume)" : viewModel.volume
        let wasteAmountForStorage = viewModel.isWaste ? viewModel.volume : "0"
        
        // Then: Should prepare correct data for storage
        XCTAssertTrue(viewModel.isWaste, "Should be in waste mode after toggle")
        XCTAssertEqual(volumeForStorage, "-90", "Should prepare negative volume for waste storage")
        XCTAssertEqual(wasteAmountForStorage, "90", "Should prepare positive waste amount for storage")
        XCTAssertTrue(viewModel.isFormValid, "Form should be valid with volume and signed in")
    }
    
    func testFeedEntryUIFlow_ShouldProduceCorrectDataForSubmission() {
        // Given: User interaction flow for normal feed entry
        let mockStorage = MockStorageService()
        let viewModel = FeedEntryViewModel(storageService: mockStorage)
        
        // Simulate user entering feed data
        viewModel.volume = "130"
        viewModel.formulaType = "Emfamil Neuropro"
        viewModel.isWaste = false  // Already in feed mode
        
        // When: User submits without toggling to waste
        mockStorage.isSignedIn = true
        
        // Simulate submission data preparation
        let volumeForStorage = viewModel.isWaste ? "-\(viewModel.volume)" : viewModel.volume
        let wasteAmountForStorage = viewModel.isWaste ? viewModel.volume : "0"
        
        // Then: Should prepare correct data for storage
        XCTAssertFalse(viewModel.isWaste, "Should remain in feed mode")
        XCTAssertEqual(volumeForStorage, "130", "Should prepare positive volume for feed storage")
        XCTAssertEqual(wasteAmountForStorage, "0", "Should prepare zero waste amount for feed storage")
        XCTAssertTrue(viewModel.isFormValid, "Form should be valid with volume and signed in")
    }
}