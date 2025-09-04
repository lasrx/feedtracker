import Foundation
import SwiftUI

/// Shared business logic for pumping entry operations
/// Follows the same MVVM pattern as FeedEntryViewModel for architectural consistency
@MainActor
class PumpingEntryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var volume = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var totalVolumeToday: Int = 0
    @Published var isDragging = false
    @Published var dragStartVolume: Int = 0
    @Published var isSubmitting = false
    
    // MARK: - Private Properties
    private var lastActiveTime = Date()
    private var lastHapticVolume: Int = 0
    
    // MARK: - Dependencies
    private var storageService: GoogleSheetsStorageService
    private let hapticHelper = HapticHelper.shared
    
    // MARK: - AppStorage Properties
    @AppStorage(FeedConstants.UserDefaultsKeys.dailyVolumeGoal) 
    var dailyVolumeGoal = FeedConstants.defaultDailyVolumeGoal
    
    @AppStorage(FeedConstants.UserDefaultsKeys.hapticFeedbackEnabled) 
    private var hapticFeedbackEnabled = true
    
    @AppStorage(FeedConstants.UserDefaultsKeys.pumpingQuickVolumes) 
    private var pumpingQuickVolumesData = "130,140,150,170"
    
    @AppStorage(FeedConstants.UserDefaultsKeys.dragSpeed)
    private var dragSpeedRawValue = FeedConstants.DragSpeed.default.rawValue
    
    // MARK: - Computed Properties
    
    var dragSpeed: FeedConstants.DragSpeed {
        return FeedConstants.DragSpeed(rawValue: dragSpeedRawValue) ?? .default
    }
    
    var quickVolumes: [String] {
        return pumpingQuickVolumesData.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var isFormValid: Bool {
        !volume.isEmpty && storageService.isSignedIn && !isSubmitting
    }
    
    var progressPercentage: Double {
        guard dailyVolumeGoal > 0 else { return 0 }
        return Double(totalVolumeToday) / Double(dailyVolumeGoal)
    }
    
    // MARK: - Initialization
    
    init(storageService: GoogleSheetsStorageService) {
        self.storageService = storageService
        
        // Prepare haptic generators for optimal performance
        hapticHelper.prepareGenerators()
    }
    
    // MARK: - Data Loading Methods
    
    func loadTodayTotal() {
        #if DEBUG
        print("PumpingEntryViewModel: loadTodayTotal called, isSignedIn: \(storageService.isSignedIn)")
        #endif
        
        guard storageService.isSignedIn else { 
            #if DEBUG
            print("PumpingEntryViewModel: Not signed in, skipping load")
            #endif
            return 
        }
        
        Task {
            do {
                #if DEBUG
                print("PumpingEntryViewModel: Calling fetchTodayPumpingTotal...")
                #endif
                let total = try await storageService.fetchTodayPumpingTotal(forceRefresh: false)
                #if DEBUG
                print("PumpingEntryViewModel: Received pumping total: \(total)mL")
                #endif
                totalVolumeToday = total
                #if DEBUG
                print("PumpingEntryViewModel: Updated UI with pumping total: \(totalVolumeToday)mL")
                #endif
            } catch {
                #if DEBUG
                print("Error loading today's pumping total: \(error)")
                #endif
            }
        }
    }
    
    func loadTodayTotalAsync() async {
        guard storageService.isSignedIn else { return }
        
        do {
            let total = try await storageService.fetchTodayPumpingTotal(forceRefresh: true)
            totalVolumeToday = total
        } catch {
            print("Error loading today's pumping total: \(error)")
        }
    }
    
    // MARK: - App Lifecycle Methods
    
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
    
    func refreshInterface() {
        // Reset form to fresh state for new entry
        selectedDate = Date()
        selectedTime = Date()
        volume = ""
        
        // Refresh today's total
        loadTodayTotal()
        
        // Light haptic feedback to indicate refresh
        hapticHelper.light(enabled: hapticFeedbackEnabled)
        
        #if DEBUG
        print("PumpingEntryViewModel: Interface refreshed after extended absence")
        #endif
    }
    
    // MARK: - Sign-in Status Handling
    
    func handleSignInStatusChange(isSignedIn: Bool) {
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
        // Use user-configurable drag sensitivity (consistent with feed logging)
        let change = Int(translation.height / dragSpeed.sensitivity)
        let originalStart = Int(volume) ?? 0
        let rawNewVolume = originalStart + change
        
        // Round to nearest 5 mL increment for easier data entry
        let newVolume = max(
            FeedConstants.minVolumeLimit, 
            min(FeedConstants.maxVolumeLimit, (rawNewVolume / 5) * 5)
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
        volume = "\(dragStartVolume)"
        hapticHelper.volumeDragEnd(enabled: hapticFeedbackEnabled)
    }
    
    // MARK: - Quick Volume Selection
    
    func selectQuickVolume(_ amount: String) {
        volume = amount
        hapticHelper.light(enabled: hapticFeedbackEnabled)
    }
    
    // MARK: - Pumping Session Submission
    
    func submitEntry() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = FeedConstants.DateFormats.sheetDate
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = FeedConstants.DateFormats.displayTime
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        let timeString = timeFormatter.string(from: selectedTime)
        
        Task {
            do {
                try await storageService.appendPumping(
                    date: dateString,
                    time: timeString,
                    volume: volume
                )
                
                // Success - show success message
                alertMessage = "Saved: \(volume) mL pumping session"
                showingAlert = true
                isSubmitting = false
                
                // Success haptic
                hapticHelper.success(enabled: hapticFeedbackEnabled)
                
                // Update today's total if it's today
                if Calendar.current.isDateInToday(selectedDate) {
                    do {
                        let total = try await storageService.fetchTodayPumpingTotal(forceRefresh: false)
                        totalVolumeToday = total
                    } catch {
                        print("Error refreshing pumping total: \(error)")
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
    
    // MARK: - Alert Handling
    
    func dismissAlert() {
        showingAlert = false
        // Clear volume after dismissing alert if submission was successful
        if !alertMessage.hasPrefix("Error") {
            volume = ""
        }
    }
}