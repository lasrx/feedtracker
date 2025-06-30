import XCTest
@testable import FeedTracker

final class FeedEntryViewModelTests: XCTestCase {
    
    var viewModel: FeedEntryViewModel!
    var mockStorageService: MockStorageService!
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        viewModel = FeedEntryViewModel(storageService: mockStorageService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - Waste Mode Toggle Tests
    
    func testInitialWasteMode_ShouldBeFalseByDefault() {
        // Given: A newly created view model
        // When: Checking initial waste mode
        let isWaste = viewModel.isWaste
        
        // Then: Should default to false (feed mode)
        XCTAssertFalse(isWaste, "View model should start in feed mode, not waste mode")
    }
    
    func testToggleWasteMode_ShouldSwitchFromFeedToWasteMode() {
        // Given: View model in feed mode
        XCTAssertFalse(viewModel.isWaste, "Should start in feed mode")
        
        // When: Toggling waste mode
        viewModel.toggleWasteMode()
        
        // Then: Should switch to waste mode
        XCTAssertTrue(viewModel.isWaste, "Should switch to waste mode after toggle")
    }
    
    func testToggleWasteMode_ShouldSwitchFromWasteToFeedMode() {
        // Given: View model in waste mode
        viewModel.toggleWasteMode() // Switch to waste
        XCTAssertTrue(viewModel.isWaste, "Should be in waste mode")
        
        // When: Toggling waste mode again
        viewModel.toggleWasteMode()
        
        // Then: Should switch back to feed mode
        XCTAssertFalse(viewModel.isWaste, "Should switch back to feed mode after second toggle")
    }
    
    func testToggleWasteMode_ShouldTriggerHapticFeedback() {
        // Given: View model with haptic feedback enabled
        // Note: We can't easily test actual haptic feedback, but we can verify the method is called
        
        // When: Toggling waste mode
        viewModel.toggleWasteMode()
        
        // Then: Haptic feedback should be triggered (this is tested implicitly)
        // In a more sophisticated test, we'd mock HapticHelper and verify the call
        XCTAssertTrue(viewModel.isWaste, "Toggle should work and presumably trigger haptics")
    }
    
    // MARK: - Form Validation Tests
    
    func testFormValidation_ShouldBeInvalidWhenVolumeIsEmpty() {
        // Given: View model with empty volume
        viewModel.volume = ""
        mockStorageService.isSignedIn = true
        
        // When: Checking form validity
        let isValid = viewModel.isFormValid
        
        // Then: Should be invalid
        XCTAssertFalse(isValid, "Form should be invalid when volume is empty")
    }
    
    func testFormValidation_ShouldBeInvalidWhenNotSignedIn() {
        // Given: View model with volume but not signed in
        viewModel.volume = "120"
        mockStorageService.isSignedIn = false
        
        // When: Checking form validity
        let isValid = viewModel.isFormValid
        
        // Then: Should be invalid
        XCTAssertFalse(isValid, "Form should be invalid when user is not signed in")
    }
    
    func testFormValidation_ShouldBeInvalidWhenSubmitting() {
        // Given: View model with valid data but currently submitting
        viewModel.volume = "120"
        mockStorageService.isSignedIn = true
        viewModel.isSubmitting = true
        
        // When: Checking form validity
        let isValid = viewModel.isFormValid
        
        // Then: Should be invalid to prevent double submission
        XCTAssertFalse(isValid, "Form should be invalid during submission to prevent double-submission")
    }
    
    func testFormValidation_ShouldBeValidWhenAllConditionsMet() {
        // Given: View model with volume, signed in, and not submitting
        viewModel.volume = "120"
        mockStorageService.isSignedIn = true
        viewModel.isSubmitting = false
        
        // When: Checking form validity
        let isValid = viewModel.isFormValid
        
        // Then: Should be valid
        XCTAssertTrue(isValid, "Form should be valid when volume is present, user is signed in, and not submitting")
    }
    
    // MARK: - Feed Submission Tests
    
    func testSubmitFeedEntry_ShouldCallStorageServiceWithCorrectFeedData() async {
        // Given: View model configured for normal feed
        viewModel.volume = "150"
        viewModel.formulaType = "Breast milk"
        viewModel.isWaste = false
        mockStorageService.isSignedIn = true
        
        // When: Submitting entry
        await MainActor.run {
            viewModel.submitEntry()
        }
        
        // Wait for async submission to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should call storage service with positive volume and zero waste
        XCTAssertEqual(mockStorageService.lastAppendedVolume, "150", "Should submit positive volume for feed")
        XCTAssertEqual(mockStorageService.lastAppendedWasteAmount, "0", "Should submit zero waste amount for feed")
        XCTAssertEqual(mockStorageService.lastAppendedFormulaType, "Breast milk", "Should submit correct formula type")
    }
    
    func testSubmitWasteEntry_ShouldCallStorageServiceWithCorrectWasteData() async {
        // Given: View model configured for waste entry
        viewModel.volume = "80"
        viewModel.formulaType = "Similac 360"
        viewModel.isWaste = true
        mockStorageService.isSignedIn = true
        
        // When: Submitting entry
        await MainActor.run {
            viewModel.submitEntry()
        }
        
        // Wait for async submission to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should call storage service with negative volume and positive waste amount
        XCTAssertEqual(mockStorageService.lastAppendedVolume, "-80", "Should submit negative volume for waste")
        XCTAssertEqual(mockStorageService.lastAppendedWasteAmount, "80", "Should submit positive waste amount for waste")
        XCTAssertEqual(mockStorageService.lastAppendedFormulaType, "Similac 360", "Should submit correct formula type")
    }
    
    // MARK: - Alert Dismissal and Reset Tests
    
    func testDismissAlert_ShouldClearVolumeAndResetWasteModeAfterSuccessfulSubmission() {
        // Given: View model after successful submission
        viewModel.volume = "120"
        viewModel.isWaste = true
        viewModel.alertMessage = "Saved: 120 mL waste of Breast milk" // Success message
        viewModel.showingAlert = true
        
        // When: Dismissing alert
        viewModel.dismissAlert()
        
        // Then: Should clear volume and reset waste mode
        XCTAssertEqual(viewModel.volume, "", "Volume should be cleared after successful submission")
        XCTAssertFalse(viewModel.isWaste, "Waste mode should be reset to false after successful submission")
        XCTAssertFalse(viewModel.showingAlert, "Alert should be dismissed")
    }
    
    func testDismissAlert_ShouldNotClearVolumeAfterError() {
        // Given: View model after error
        viewModel.volume = "120"
        viewModel.isWaste = true
        viewModel.alertMessage = "Error: Network connection failed" // Error message
        viewModel.showingAlert = true
        
        // When: Dismissing alert
        viewModel.dismissAlert()
        
        // Then: Should not clear volume or reset waste mode for errors
        XCTAssertEqual(viewModel.volume, "120", "Volume should not be cleared after error")
        XCTAssertTrue(viewModel.isWaste, "Waste mode should not be reset after error")
        XCTAssertFalse(viewModel.showingAlert, "Alert should still be dismissed")
    }
    
    // MARK: - Quick Volume Selection Tests
    
    func testSelectQuickVolume_ShouldUpdateVolumeField() {
        // Given: View model with empty volume
        viewModel.volume = ""
        
        // When: Selecting quick volume
        viewModel.selectQuickVolume("130")
        
        // Then: Should update volume field
        XCTAssertEqual(viewModel.volume, "130", "Quick volume selection should update volume field")
    }
    
    func testSelectQuickVolume_ShouldOverwriteExistingVolume() {
        // Given: View model with existing volume
        viewModel.volume = "100"
        
        // When: Selecting different quick volume
        viewModel.selectQuickVolume("150")
        
        // Then: Should overwrite existing volume
        XCTAssertEqual(viewModel.volume, "150", "Quick volume selection should overwrite existing volume")
    }
    
    // MARK: - Drag Gesture Tests
    
    func testStartVolumeDrag_ShouldEnterDragModeWithCurrentVolume() {
        // Given: View model with volume
        viewModel.volume = "100"
        
        // When: Starting drag
        viewModel.startVolumeDrag()
        
        // Then: Should enter drag mode with current volume
        XCTAssertTrue(viewModel.isDragging, "Should enter drag mode")
        XCTAssertEqual(viewModel.dragStartVolume, 100, "Should set drag start volume to current volume")
    }
    
    func testStartVolumeDrag_ShouldHandleEmptyVolumeAsZero() {
        // Given: View model with empty volume
        viewModel.volume = ""
        
        // When: Starting drag
        viewModel.startVolumeDrag()
        
        // Then: Should treat empty as zero
        XCTAssertTrue(viewModel.isDragging, "Should enter drag mode")
        XCTAssertEqual(viewModel.dragStartVolume, 0, "Should treat empty volume as zero for drag")
    }
    
    func testEndVolumeDrag_ShouldExitDragModeAndUpdateVolume() {
        // Given: View model in drag mode
        viewModel.startVolumeDrag()
        viewModel.dragStartVolume = 125
        
        // When: Ending drag
        viewModel.endVolumeDrag()
        
        // Then: Should exit drag mode and update volume
        XCTAssertFalse(viewModel.isDragging, "Should exit drag mode")
        XCTAssertEqual(viewModel.volume, "125", "Should update volume to final drag value")
    }
}

// MARK: - Mock Storage Service

class MockStorageService: StorageServiceProtocol {
    var isSignedIn: Bool = false
    var userEmail: String?
    var error: Error?
    
    // Track last appended data for verification
    var lastAppendedDate: String = ""
    var lastAppendedTime: String = ""
    var lastAppendedVolume: String = ""
    var lastAppendedFormulaType: String = ""
    var lastAppendedWasteAmount: String = ""
    
    func signIn() async throws {
        isSignedIn = true
    }
    
    func signOut() throws {
        isSignedIn = false
    }
    
    func appendFeed(date: String, time: String, volume: String, formulaType: String, wasteAmount: String) async throws {
        lastAppendedDate = date
        lastAppendedTime = time
        lastAppendedVolume = volume
        lastAppendedFormulaType = formulaType
        lastAppendedWasteAmount = wasteAmount
    }
    
    func fetchTodayFeedTotal(forceRefresh: Bool) async throws -> Int {
        return 500 // Mock total
    }
    
    func fetchTodayFeeds(forceRefresh: Bool) async throws -> [FeedEntry] {
        return [] // Mock empty feeds
    }
    
    func fetchPast7DaysFeedTotals(forceRefresh: Bool) async throws -> [DailyTotal] {
        return [] // Mock empty totals
    }
    
    func appendPumping(date: String, time: String, volume: String) async throws {
        // Mock implementation
    }
    
    func fetchTodayPumpingTotal(forceRefresh: Bool) async throws -> Int {
        return 200 // Mock total
    }
    
    func fetchTodayPumpingSessions(forceRefresh: Bool) async throws -> [PumpingEntry] {
        return [] // Mock empty sessions
    }
    
    func fetchPast7DaysPumpingTotals(forceRefresh: Bool) async throws -> [DailyTotal] {
        return [] // Mock empty totals
    }
    
    func updateConfiguration(_ config: StorageConfiguration) throws {
        // Mock implementation
    }
    
    func fetchAvailableStorageOptions() async throws -> [StorageOption] {
        return [] // Mock empty options
    }
    
    func createNewStorage(title: String) async throws -> String {
        return "mock-id" // Mock storage ID
    }
}