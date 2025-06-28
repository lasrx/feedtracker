import Foundation
import SwiftUI
import AppIntents

/// Shared business logic for feed entry operations
/// Eliminates code duplication between ContentView and FeedLoggingView
@MainActor
class FeedEntryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var volume = ""
    @Published var formulaType = "Breast milk"
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var lastFeedTime: Date?
    @Published var lastFeedVolume: String?
    @Published var totalVolumeToday: Int = 0
    @Published var isDragging = false
    @Published var dragStartVolume: Int = 0
    @Published var isSubmitting = false
    @Published var showingSettings = false
    
    // MARK: - Private Properties
    private var lastActiveTime = Date()
    private var lastHapticVolume: Int = 0
    private var dragVelocity: Double = 0
    private var lastDragTime = Date()
    
    // MARK: - Dependencies
    private var storageService: any StorageServiceProtocol
    private let hapticHelper = HapticHelper.shared
    
    // MARK: - AppStorage Properties
    @AppStorage(FeedConstants.UserDefaultsKeys.dailyVolumeGoal) 
    var dailyVolumeGoal = FeedConstants.defaultDailyVolumeGoal
    
    @AppStorage(FeedConstants.UserDefaultsKeys.formulaTypes) 
    private var formulaTypesData = ""
    
    @AppStorage(FeedConstants.UserDefaultsKeys.hapticFeedbackEnabled) 
    private var hapticFeedbackEnabled = true
    
    @AppStorage(FeedConstants.UserDefaultsKeys.feedQuickVolumes) 
    private var feedQuickVolumesData = FeedConstants.defaultQuickVolumes
    
    // MARK: - Computed Properties
    
    var quickVolumes: [String] {
        return feedQuickVolumesData.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var formulaTypes: [String] {
        if formulaTypesData.isEmpty {
            return FeedConstants.defaultFormulaTypes
        }
        return formulaTypesData.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var isFormValid: Bool {
        !volume.isEmpty && sheetsService.isSignedIn && !isSubmitting
    }
    
    var progressPercentage: Double {
        guard dailyVolumeGoal > 0 else { return 0 }
        return Double(totalVolumeToday) / Double(dailyVolumeGoal)
    }
    
    // MARK: - Initialization
    
    init(storageService: any StorageServiceProtocol) {
        self.storageService = storageService
        
        // Set default formula type
        formulaType = formulaTypes.first ?? "Breast milk"
        
        // Prepare haptic generators for optimal performance
        hapticHelper.prepareGenerators()
    }
    
    // MARK: - Data Loading Methods
    
    func loadTodayTotal() {
        guard storageService.isSignedIn else { return }
        
        Task {
            do {
                let total = try await storageService.fetchTodayFeedTotal()
                totalVolumeToday = total
            } catch {
                print("Error loading today's total: \(error)")
            }
        }
    }
    
    func loadTodayTotalAsync() async {
        guard storageService.isSignedIn else { return }
        
        do {
            let total = try await storageService.fetchTodayFeedTotal()
            totalVolumeToday = total
        } catch {
            print("Error loading today's total: \(error)")
        }
    }
    
    // MARK: - Interface Management
    
    func refreshInterface() {
        // Reset form to fresh state for new entry
        selectedDate = Date()
        selectedTime = Date()
        volume = ""
        
        // Reset last used formula type to default
        formulaType = formulaTypes.first ?? "Breast milk"
        
        // Refresh today's total
        loadTodayTotal()
        
        // Light haptic feedback to indicate refresh
        hapticHelper.light(enabled: hapticFeedbackEnabled)
        
        print("Interface refreshed after extended absence")
    }
    
    func handleAppWillEnterForeground() {
        // App is returning from background
        let timeSinceLastActive = Date().timeIntervalSince(lastActiveTime)
        
        // If app was backgrounded for more than 1 hour, refresh interface
        if timeSinceLastActive > FeedConstants.backgroundRefreshThreshold {
            refreshInterface()
        }
        
        lastActiveTime = Date()
    }
    
    func handleAppDidEnterBackground() {
        // App is going to background - record the time
        lastActiveTime = Date()
    }
    
    func handleSignInStatusChange(isSignedIn: Bool) {
        // Load today's total when sign-in status changes
        if isSignedIn {
            loadTodayTotal()
        } else {
            totalVolumeToday = 0
        }
    }
    
    // MARK: - Volume Drag Gesture Methods
    
    func startVolumeDrag() {
        isDragging = true
        dragStartVolume = Int(volume) ?? 0
        lastHapticVolume = dragStartVolume
        hapticHelper.volumeDragStart(enabled: hapticFeedbackEnabled)
    }
    
    func updateVolumeDrag(translation: CGSize) {
        // Use centralized drag sensitivity
        let change = Int(translation.height / FeedConstants.dragSensitivity)
        let originalStart = Int(volume) ?? 0
        let newVolume = max(
            FeedConstants.minVolumeLimit, 
            min(FeedConstants.maxVolumeLimit, originalStart + change)
        )
        
        // Update dragStartVolume for visual feedback during drag
        dragStartVolume = newVolume
        
        // Handle haptic feedback for volume increments
        lastHapticVolume = hapticHelper.volumeDragIncrement(
            volume: newVolume,
            lastHapticVolume: lastHapticVolume,
            enabled: hapticFeedbackEnabled
        )
    }
    
    func endVolumeDrag() {
        isDragging = false
        volume = "\(dragStartVolume)" // Update the volume string with final value
        hapticHelper.volumeDragEnd(enabled: hapticFeedbackEnabled)
    }
    
    // MARK: - Quick Volume Selection
    
    func selectQuickVolume(_ amount: String) {
        volume = amount
        hapticHelper.light(enabled: hapticFeedbackEnabled)
    }
    
    func selectLastVolume() {
        guard let lastVolume = lastFeedVolume else { return }
        volume = lastVolume
        hapticHelper.light(enabled: hapticFeedbackEnabled)
    }
    
    // MARK: - Feed Submission
    
    func submitEntry() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = FeedConstants.DateFormats.sheetDate
        let dateString = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = FeedConstants.DateFormats.displayTime
        let timeString = timeFormatter.string(from: selectedTime)
        
        Task {
            do {
                // Save to storage
                try await storageService.appendFeed(
                    date: dateString,
                    time: timeString,
                    volume: volume,  // Just the number, no "mL"
                    formulaType: formulaType
                )
                
                // Success - update tracking variables
                lastFeedTime = selectedTime
                lastFeedVolume = volume
                
                // Haptic feedback for success
                hapticHelper.success(enabled: hapticFeedbackEnabled)
                
                // Show success message
                alertMessage = "Saved: \(volume) mL of \(formulaType)"
                showingAlert = true
                isSubmitting = false
                
                // Save last used formula type for Siri
                UserDefaults.standard.set(formulaType, forKey: FeedConstants.UserDefaultsKeys.lastUsedFormulaType)
                
                // Donate to Siri for future voice commands
                await donateSiriIntent()
                
                // Update today's total if it's today
                if Calendar.current.isDateInToday(selectedDate) {
                    do {
                        let total = try await storageService.fetchTodayFeedTotal()
                        totalVolumeToday = total
                    } catch {
                        print("Error refreshing total: \(error)")
                    }
                }
            } catch {
                // Error - show error message
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
                isSubmitting = false
                
                // Error haptic
                hapticHelper.error(enabled: hapticFeedbackEnabled)
            }
        }
    }
    
    // MARK: - Siri Integration
    
    private func donateSiriIntent() async {
        let intent = LogFeedIntent()
        intent.volume = VolumeEntity(id: Int(volume) ?? 0)
        
        // Simplified donation
        do {
            try await intent.donate()
        } catch {
            print("Failed to donate Siri intent: \(error)")
        }
    }
    
    // MARK: - Alert Handling
    
    func dismissAlert() {
        showingAlert = false
        // Clear volume after dismissing alert if submission was successful
        if !alertMessage.hasPrefix("Error") {
            volume = ""
        }
    }
    
    // MARK: - Settings Management
    
    func showSettings() {
        showingSettings = true
    }
    
    func hideSettings() {
        showingSettings = false
    }
    
}