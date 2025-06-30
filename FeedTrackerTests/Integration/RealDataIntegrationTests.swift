import XCTest
@testable import FeedTracker

final class RealDataIntegrationTests: XCTestCase {
    
    // MARK: - Real Data Calculation Tests
    
    func testRealFeedData_ShouldCalculateCorrectTodayTotals() {
        // Given: Real feed data for today (6/29/2025)
        let todayEntries = RealDataTestProvider.getEntriesForDate("6/29/2025", from: RealDataTestProvider.realFeedEntries)
        
        // When: Calculating totals like GoogleSheetsService.fetchTodayFeedTotal would
        let totalEffectiveVolume = todayEntries.reduce(0) { $0 + $1.effectiveVolume }
        let feedEntries = todayEntries.filter { !$0.isWaste }
        let wasteEntries = todayEntries.filter { $0.isWaste }
        let totalFeedVolume = feedEntries.reduce(0) { $0 + $1.actualVolume }
        let totalWasteVolume = wasteEntries.reduce(0) { $0 + $1.actualVolume }
        
        // Then: Should match expected real-world totals
        // Real data: 120 + 140 + (-30) + 160 + 130 + (-20) + 150 + 180 + 100 = 930 mL effective
        XCTAssertEqual(totalEffectiveVolume, 930, "Total effective volume should account for waste subtractions")
        XCTAssertEqual(totalFeedVolume, 980, "Total feed volume should be 120+140+160+130+150+180+100 = 980 mL")
        XCTAssertEqual(totalWasteVolume, 50, "Total waste should be 30+20 = 50 mL")
        XCTAssertEqual(feedEntries.count, 7, "Should have 7 actual feed entries today")
        XCTAssertEqual(wasteEntries.count, 2, "Should have 2 waste entries today")
    }
    
    func testRealFeedData_ShouldCalculateCorrectAverageVolume() {
        // Given: Real feed data excluding waste
        let todayEntries = RealDataTestProvider.getEntriesForDate("6/29/2025", from: RealDataTestProvider.realFeedEntries)
        let feedOnlyEntries = todayEntries.filter { !$0.isWaste }
        
        // When: Calculating average like FeedHistoryView would
        let totalFeedVolume = feedOnlyEntries.reduce(0) { $0 + $1.actualVolume }
        let averageVolume = feedOnlyEntries.isEmpty ? 0 : totalFeedVolume / feedOnlyEntries.count
        
        // Then: Should calculate correct average
        // (120 + 140 + 160 + 130 + 150 + 180 + 100) / 7 = 980 / 7 = 140 mL
        XCTAssertEqual(averageVolume, 140, "Average feed volume should be 140 mL excluding waste")
    }
    
    func testRealFeedData_ShouldIdentifyMostCommonFormulaType() {
        // Given: Real feed data with various formula types
        let todayEntries = RealDataTestProvider.getEntriesForDate("6/29/2025", from: RealDataTestProvider.realFeedEntries)
        
        // When: Finding most common formula like FeedHistoryView would
        let mostCommonFormula = RealDataTestProvider.getMostCommonFormulaType(from: todayEntries)
        
        // Then: Should identify the most frequently used formula
        // Real data has: Breast milk (4x), Similac 360 (1x), Emfamil Neuropro (2x)
        XCTAssertEqual(mostCommonFormula, "Breast milk", "Most common formula should be Breast milk based on real usage")
    }
    
    // MARK: - Legacy Data Compatibility Tests
    
    func testLegacy4ColumnData_ShouldParseCorrectlyWithZeroWaste() {
        // Given: Real legacy 4-column data from older spreadsheets
        let legacyRows = RealDataTestProvider.legacy4ColumnData
        
        // When: Parsing like GoogleSheetsStorageService.fetchTodayFeeds would
        let parsedEntries = RealDataTestProvider.parseFeedEntriesFromRows(legacyRows)
        
        // Then: Should parse correctly with zero waste amounts
        XCTAssertEqual(parsedEntries.count, 4, "Should parse all 4 legacy entries")
        
        for entry in parsedEntries {
            XCTAssertEqual(entry.wasteAmount, 0, "Legacy entries should have zero waste amount")
            XCTAssertFalse(entry.isWaste, "Legacy entries should not be identified as waste")
            XCTAssertGreaterThan(entry.volume, 0, "Legacy entries should have positive volumes")
        }
        
        // Verify specific entries
        XCTAssertEqual(parsedEntries[0].volume, 120, "First legacy entry should have 120 mL")
        XCTAssertEqual(parsedEntries[0].formulaType, "Breast milk", "First legacy entry should be breast milk")
    }
    
    func testNew5ColumnData_ShouldParseCorrectlyWithWasteAmounts() {
        // Given: Real new 5-column data with waste tracking
        let newRows = RealDataTestProvider.new5ColumnData
        
        // When: Parsing like GoogleSheetsStorageService.fetchTodayFeeds would
        let parsedEntries = RealDataTestProvider.parseFeedEntriesFromRows(newRows)
        
        // Then: Should parse correctly including waste entries
        XCTAssertEqual(parsedEntries.count, 6, "Should parse all 6 new entries")
        
        let wasteEntries = parsedEntries.filter { $0.isWaste }
        let feedEntries = parsedEntries.filter { !$0.isWaste }
        
        XCTAssertEqual(wasteEntries.count, 2, "Should identify 2 waste entries")
        XCTAssertEqual(feedEntries.count, 4, "Should identify 4 feed entries")
        
        // Verify waste entries have consistent data
        for wasteEntry in wasteEntries {
            XCTAssertLessThan(wasteEntry.volume, 0, "Waste entries should have negative volume")
            XCTAssertGreaterThan(wasteEntry.wasteAmount, 0, "Waste entries should have positive waste amount")
            XCTAssertEqual(wasteEntry.actualVolume, wasteEntry.wasteAmount, "Actual volume should match waste amount")
        }
        
        // Verify specific waste entry
        let firstWasteEntry = wasteEntries.first { $0.time == "11:45 AM" }
        XCTAssertNotNil(firstWasteEntry, "Should find waste entry at 11:45 AM")
        XCTAssertEqual(firstWasteEntry?.volume, -30, "Waste entry should have -30 mL volume")
        XCTAssertEqual(firstWasteEntry?.wasteAmount, 30, "Waste entry should have 30 mL waste amount")
    }
    
    // MARK: - Edge Case Tests with Real Data
    
    func testEdgeCaseData_ShouldHandleTimeFormatVariations() {
        // Given: Real edge case data with time format variations
        let edgeRows = RealDataTestProvider.edgeCaseData
        
        // When: Parsing edge case data
        let parsedEntries = RealDataTestProvider.parseFeedEntriesFromRows(edgeRows)
        
        // Then: Should handle all time format variations
        let timeVariations = parsedEntries.map { $0.time }
        
        XCTAssertTrue(timeVariations.contains("9:05 AM"), "Should handle single digit minutes")
        XCTAssertTrue(timeVariations.contains("12:00 PM"), "Should handle noon exactly")
        XCTAssertTrue(timeVariations.contains("12:00 AM"), "Should handle midnight exactly")
        
        // All entries should parse successfully
        XCTAssertEqual(parsedEntries.count, edgeRows.count, "Should parse all edge case entries")
    }
    
    func testEdgeCaseData_ShouldHandleFormulaNameVariations() {
        // Given: Real edge case data with formula name variations
        let edgeRows = RealDataTestProvider.edgeCaseData
        let parsedEntries = RealDataTestProvider.parseFeedEntriesFromRows(edgeRows)
        
        // When: Checking formula type variations
        let formulaTypes = Set(parsedEntries.map { $0.formulaType })
        
        // Then: Should preserve all formula name variations
        XCTAssertTrue(formulaTypes.contains("breast milk"), "Should handle lowercase formula names")
        XCTAssertTrue(formulaTypes.contains("Similac Pro"), "Should handle shortened formula names")
        XCTAssertTrue(formulaTypes.contains("Enfamil"), "Should handle common misspellings")
        
        // Should not lose any data due to format variations
        let formulaEntries = parsedEntries.filter { 
            ["breast milk", "Similac Pro", "Enfamil"].contains($0.formulaType) 
        }
        XCTAssertEqual(formulaEntries.count, 3, "Should preserve all formula name variations")
    }
    
    func testEdgeCaseData_ShouldHandleVolumeExtremes() {
        // Given: Real edge case data with volume extremes
        let edgeRows = RealDataTestProvider.edgeCaseData
        let parsedEntries = RealDataTestProvider.parseFeedEntriesFromRows(edgeRows)
        
        // When: Checking volume extremes
        let volumes = parsedEntries.map { $0.actualVolume }
        let wasteVolumes = parsedEntries.filter { $0.isWaste }.map { $0.actualVolume }
        
        // Then: Should handle high and low volumes correctly
        XCTAssertTrue(volumes.contains(200), "Should handle high volume (200 mL)")
        XCTAssertTrue(volumes.contains(30), "Should handle low volume (30 mL)")
        XCTAssertTrue(wasteVolumes.contains(5), "Should handle small waste amount (5 mL)")
        XCTAssertTrue(wasteVolumes.contains(90), "Should handle large waste amount (90 mL)")
        
        // All volumes should be positive when converted to actual volume
        for volume in volumes {
            XCTAssertGreaterThan(volume, 0, "All actual volumes should be positive")
        }
    }
    
    // MARK: - Weekly Summary Tests with Real Data
    
    func testRealWeeklyData_ShouldCalculate7DayTotalsCorrectly() {
        // Given: Real data spanning multiple days
        let allEntries = RealDataTestProvider.realFeedEntries
        
        // When: Calculating 7-day totals
        let mockToday = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 29))!
        let weeklyTotals = RealDataTestProvider.calculatePast7DayTotals(from: allEntries, today: mockToday)
        
        // Then: Should have daily totals for past 7 days
        XCTAssertEqual(weeklyTotals.count, 7, "Should have 7 daily totals")
        
        // Check specific day totals
        let june28Total = weeklyTotals.first { Calendar.current.isDate($0.date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: mockToday)!) }
        XCTAssertNotNil(june28Total, "Should have total for June 28")
        // June 28: 110 + 145 + (-25) + 165 = 395 mL
        XCTAssertEqual(june28Total?.volume, 395, "June 28 total should be 395 mL including waste")
        
        let june22Total = weeklyTotals.first { Calendar.current.isDate($0.date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -7, to: mockToday)!) }
        XCTAssertNotNil(june22Total, "Should have total for June 22")
        // June 22: 95 + 125 + 140 = 360 mL
        XCTAssertEqual(june22Total?.volume, 360, "June 22 total should be 360 mL")
    }
    
    // MARK: - Calculation Verification Tests
    
    func testCalculationTestData_ShouldProduceExactExpectedResults() {
        // Given: Carefully crafted calculation test data with known expected results
        let testData = RealDataTestProvider.calculationTestData
        
        // When: Performing all major calculations
        let totalEffectiveVolume = testData.reduce(0) { $0 + $1.effectiveVolume }
        let wasteEntries = testData.filter { $0.isWaste }
        let feedEntries = testData.filter { !$0.isWaste }
        let totalWaste = wasteEntries.reduce(0) { $0 + $1.actualVolume }
        let totalFed = feedEntries.reduce(0) { $0 + $1.actualVolume }
        let averageFeed = feedEntries.isEmpty ? 0 : totalFed / feedEntries.count
        
        // Then: Should match exactly calculated expected results
        XCTAssertEqual(totalEffectiveVolume, 380, "Total effective volume should be 120+150+(-30)+140 = 380 mL")
        XCTAssertEqual(totalWaste, 30, "Total waste should be 30 mL")
        XCTAssertEqual(totalFed, 410, "Total fed should be 120+150+140 = 410 mL")
        XCTAssertEqual(feedEntries.count, 3, "Should have exactly 3 feed entries")
        XCTAssertEqual(wasteEntries.count, 1, "Should have exactly 1 waste entry")
        XCTAssertEqual(averageFeed, 136, "Average feed should be 410/3 = 136.67 ≈ 136 mL")
    }
}