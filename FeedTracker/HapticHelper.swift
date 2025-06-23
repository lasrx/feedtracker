import UIKit
import Foundation

/// Multi-tier haptic feedback system with fallback capabilities
/// Provides subtle haptic intensities (0.7/0.5/0.3) with graceful degradation
class HapticHelper {
    
    // MARK: - Singleton
    static let shared = HapticHelper()
    private init() {}
    
    // MARK: - Haptic Intensity Levels
    enum HapticIntensity {
        case subtle    // 0.3 intensity
        case medium    // 0.5 intensity
        case strong    // 0.7 intensity
        case system    // System default intensity
    }
    
    // MARK: - Haptic Types
    enum HapticType {
        case impact(HapticIntensity)
        case selection
        case notification(UINotificationFeedbackGenerator.FeedbackType)
    }
    
    // MARK: - Cached Generators
    private var lightImpactGenerator: UIImpactFeedbackGenerator?
    private var mediumImpactGenerator: UIImpactFeedbackGenerator?
    private var heavyImpactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    // MARK: - Haptic Availability Check
    private var isHapticAvailable: Bool {
        // Check if device supports haptic feedback
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Main Haptic Method
    /// Triggers haptic feedback with specified type and intensity
    /// - Parameters:
    ///   - type: The type of haptic feedback to trigger
    ///   - enabled: Whether haptic feedback is enabled (from user settings)
    func trigger(_ type: HapticType, enabled: Bool = true) {
        guard enabled && isHapticAvailable else { return }
        
        switch type {
        case .impact(let intensity):
            triggerImpact(intensity: intensity)
        case .selection:
            triggerSelection()
        case .notification(let notificationType):
            triggerNotification(type: notificationType)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Light haptic for button taps and quick volume selections
    func light(enabled: Bool = true) {
        trigger(.impact(.subtle), enabled: enabled)
    }
    
    /// Medium haptic for drag operations and moderate feedback
    func medium(enabled: Bool = true) {
        trigger(.impact(.medium), enabled: enabled)
    }
    
    /// Strong haptic for drag start and major milestones
    func strong(enabled: Bool = true) {
        trigger(.impact(.strong), enabled: enabled)
    }
    
    /// Selection haptic for picker changes
    func selection(enabled: Bool = true) {
        trigger(.selection, enabled: enabled)
    }
    
    /// Success notification haptic
    func success(enabled: Bool = true) {
        trigger(.notification(.success), enabled: enabled)
    }
    
    /// Error notification haptic
    func error(enabled: Bool = true) {
        trigger(.notification(.error), enabled: enabled)
    }
    
    /// Warning notification haptic
    func warning(enabled: Bool = true) {
        trigger(.notification(.warning), enabled: enabled)
    }
    
    // MARK: - Volume Drag Specific Methods
    
    /// Haptic for starting a volume drag operation
    func volumeDragStart(enabled: Bool = true) {
        strong(enabled: enabled)
    }
    
    /// Haptic for volume increment milestones during drag
    /// - Parameters:
    ///   - volume: Current volume value
    ///   - lastHapticVolume: Last volume that triggered haptic
    ///   - enabled: Whether haptic is enabled
    /// - Returns: New lastHapticVolume value
    func volumeDragIncrement(volume: Int, lastHapticVolume: Int, enabled: Bool = true) -> Int {
        guard enabled else { return lastHapticVolume }
        
        // Strong haptic on 25mL boundaries, medium on 5mL boundaries
        if volume % FeedConstants.hapticVolumeIncrement == 0 && volume != lastHapticVolume {
            if volume % FeedConstants.strongHapticIncrement == 0 {
                strong(enabled: enabled)
            } else {
                medium(enabled: enabled)
            }
            return volume
        }
        return lastHapticVolume
    }
    
    /// Haptic for ending a volume drag operation
    func volumeDragEnd(enabled: Bool = true) {
        medium(enabled: enabled)
    }
    
    // MARK: - Private Implementation
    
    private func triggerImpact(intensity: HapticIntensity) {
        switch intensity {
        case .subtle:
            triggerCustomImpact(style: .light, intensity: 0.3)
        case .medium:
            triggerCustomImpact(style: .medium, intensity: 0.5)
        case .strong:
            triggerCustomImpact(style: .heavy, intensity: 0.7)
        case .system:
            // Use system default - fallback to medium
            if mediumImpactGenerator == nil {
                mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
                mediumImpactGenerator?.prepare()
            }
            mediumImpactGenerator?.impactOccurred()
        }
    }
    
    private func triggerCustomImpact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        // Try to use custom intensity if available (iOS 13+)
        if #available(iOS 13.0, *) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        } else {
            // Fallback to standard intensity for older iOS versions
            fallbackImpact(style: style)
        }
    }
    
    private func fallbackImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            if lightImpactGenerator == nil {
                lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
                lightImpactGenerator?.prepare()
            }
            lightImpactGenerator?.impactOccurred()
        case .medium:
            if mediumImpactGenerator == nil {
                mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
                mediumImpactGenerator?.prepare()
            }
            mediumImpactGenerator?.impactOccurred()
        case .heavy:
            if heavyImpactGenerator == nil {
                heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                heavyImpactGenerator?.prepare()
            }
            heavyImpactGenerator?.impactOccurred()
        @unknown default:
            // Fallback to medium for unknown styles
            if mediumImpactGenerator == nil {
                mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
                mediumImpactGenerator?.prepare()
            }
            mediumImpactGenerator?.impactOccurred()
        }
    }
    
    private func triggerSelection() {
        if selectionGenerator == nil {
            selectionGenerator = UISelectionFeedbackGenerator()
            selectionGenerator?.prepare()
        }
        selectionGenerator?.selectionChanged()
    }
    
    private func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        if notificationGenerator == nil {
            notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator?.prepare()
        }
        notificationGenerator?.notificationOccurred(type)
    }
    
    // MARK: - Memory Management
    
    /// Clears cached generators to free memory
    func clearCache() {
        lightImpactGenerator = nil
        mediumImpactGenerator = nil
        heavyImpactGenerator = nil
        selectionGenerator = nil
        notificationGenerator = nil
    }
    
    /// Prepares generators for immediate use (reduces latency)
    func prepareGenerators() {
        lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        
        lightImpactGenerator?.prepare()
        mediumImpactGenerator?.prepare()
        heavyImpactGenerator?.prepare()
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
    }
}