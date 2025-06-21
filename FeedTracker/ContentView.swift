import SwiftUI
import GoogleSignIn
import AppIntents

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var volume = ""
    @State private var formulaType = "Breast milk"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var lastFeedTime: Date?
    @State private var lastFeedVolume: String?
    @State private var totalVolumeToday: Int = 0
    @State private var isDragging = false
    @State private var dragStartVolume: Int = 0
    @State private var isSubmitting = false
    @State private var showingSettings = false
    @State private var lastActiveTime = Date()
    @State private var lastHapticVolume: Int = 0
    @State private var dragVelocity: Double = 0
    @State private var lastDragTime = Date()
    
    @StateObject private var sheetsService = GoogleSheetsService()
    @AppStorage("dailyVolumeGoal") private var dailyVolumeGoal = 1000
    @AppStorage("formulaTypes") private var formulaTypesData = ""
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    // Default formula types
    private let defaultFormulaTypes = ["Breast milk", "Similac 360", "Emfamil Neuropro"]
    @AppStorage("feedQuickVolumes") private var feedQuickVolumesData = "40,60,130,150"
    
    var quickVolumes: [String] {
        return feedQuickVolumesData.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var formulaTypes: [String] {
        if formulaTypesData.isEmpty {
            return defaultFormulaTypes
        }
        return formulaTypesData.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // Dark mode aware colors
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                // Sign-in prompt if not signed in
                if !sheetsService.isSignedIn {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.key")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Sign in to Google to save feeds")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text("Tap the settings gear above to sign in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Today's Summary Card
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Today's Feed Total", systemImage: "chart.bar.fill")
                            .font(.headline)
                        
                        HStack(alignment: .bottom) {
                            Text("\(totalVolumeToday) mL")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            
                            Text("/ \(dailyVolumeGoal) mL goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar
                        ProgressView(value: Double(totalVolumeToday), total: Double(dailyVolumeGoal))
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 1.5)
                        
                        if let lastTime = lastFeedTime {
                            let timeAgo = RelativeTimeFormatter.shared.string(from: lastTime)
                            Text("Last feed: \(timeAgo)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                )
                
                Section(header: Text("Feed Details")) {
                    // Date Picker with larger tap area
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Time Picker with larger tap area
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Volume with swipe gesture
                    HStack {
                        Text("Volume")
                        Spacer()
                        HStack {
                            if isDragging {
                                Text("\(dragStartVolume)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 120, height: 60)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(8)
                            } else {
                                TextField("0", text: $volume)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .font(.system(size: 17))
                            }
                            
                            Text("mL")
                                .foregroundColor(.secondary)
                        }
                        .highPriorityGesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragStartVolume = Int(volume) ?? 0
                                        lastHapticVolume = dragStartVolume
                                        if hapticFeedbackEnabled {
                                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        }
                                    }
                                    
                                    // Even faster movement: 2.5 pixels per 1 mL
                                    let change = Int(value.translation.height / -2.5)
                                    let originalStart = Int(volume) ?? 0
                                    let newVolume = max(0, min(999, originalStart + change))
                                    
                                    // Update dragStartVolume for visual feedback during drag
                                    dragStartVolume = newVolume
                                    
                                    // Strong haptic feedback on 5mL boundaries
                                    if hapticFeedbackEnabled && newVolume % 5 == 0 && newVolume != lastHapticVolume {
                                        let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = newVolume % 25 == 0 ? .heavy : .medium
                                        UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred()
                                        lastHapticVolume = newVolume
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    volume = "\(dragStartVolume)" // Update the volume string with final value
                                    if hapticFeedbackEnabled {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                        )
                    }
                    .frame(minHeight: 44)
                    
                    // Formula Type Picker
                    Picker("Formula Type", selection: $formulaType) {
                        ForEach(formulaTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 44)
                }
                
                Section {
                    Button(action: submitEntry) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Feed Entry")
                            }
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(volume.isEmpty || !sheetsService.isSignedIn || isSubmitting)
                }
                
                Section(header: Text("Quick Actions")) {
                    // Common volume buttons for quick entry
                    VStack(spacing: 8) {
                        Text("Quick Volume Selection (mL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            // First 4 fixed volumes
                            ForEach(quickVolumes, id: \.self) { amount in
                                Button(action: {
                                    volume = amount
                                    // Haptic feedback
                                    if hapticFeedbackEnabled {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                }) {
                                    Text("\(amount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 50, height: 40)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            // Dynamic "Last" button
                            if let lastVolume = lastFeedVolume {
                                Button(action: {
                                    volume = lastVolume
                                    // Haptic feedback
                                    if hapticFeedbackEnabled {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                }) {
                                    Text("\(lastVolume)")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 50, height: 40)
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                            }
                        }
                        
                        Text("Tip: Swipe up/down on volume field to adjust")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("MiniLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    // Clear volume after dismissing alert
                    volume = ""
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Load today's total when view appears
                loadTodayTotal()
            }
            .onChange(of: sheetsService.isSignedIn) { _, isSignedIn in
                // Load today's total when sign-in status changes
                if isSignedIn {
                    loadTodayTotal()
                } else {
                    totalVolumeToday = 0
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // App is returning from background
                let timeSinceLastActive = Date().timeIntervalSince(lastActiveTime)
                
                // If app was backgrounded for more than 1 hour, refresh interface
                if timeSinceLastActive > 3600 { // 3600 seconds = 1 hour
                    refreshInterface()
                }
                
                lastActiveTime = Date()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // App is going to background - record the time
                lastActiveTime = Date()
            }
            .refreshable {
                // Pull to refresh
                await loadTodayTotalAsync()
            }
        }
        .preferredColorScheme(nil) // Respects system dark mode setting
    }
    
    private func loadTodayTotal() {
        guard sheetsService.isSignedIn else { return }
        
        Task {
            do {
                let total = try await sheetsService.fetchTodayTotal()
                await MainActor.run {
                    totalVolumeToday = total
                }
            } catch {
                print("Error loading today's total: \(error)")
            }
        }
    }
    
    private func loadTodayTotalAsync() async {
        guard sheetsService.isSignedIn else { return }
        
        do {
            let total = try await sheetsService.fetchTodayTotal()
            await MainActor.run {
                totalVolumeToday = total
            }
        } catch {
            print("Error loading today's total: \(error)")
        }
    }
    
    private func refreshInterface() {
        // Reset form to fresh state for new entry
        selectedDate = Date()
        selectedTime = Date()
        volume = ""
        
        // Reset last used formula type to default
        formulaType = formulaTypes.first ?? "Breast milk"
        
        // Refresh today's total
        loadTodayTotal()
        
        // Light haptic feedback to indicate refresh
        if hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        print("Interface refreshed after extended absence")
    }
    
    private func submitEntry() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"  // 12-hour format with AM/PM
        let timeString = timeFormatter.string(from: selectedTime)
        
        Task {
            do {
                // Save to Google Sheets
                try await sheetsService.appendRow(
                    date: dateString,
                    time: timeString,
                    volume: volume,  // Just the number, no "mL"
                    formulaType: formulaType
                )
                
                // Success - update UI on main thread
                await MainActor.run {
                    // Update tracking variables
                    lastFeedTime = selectedTime
                    lastFeedVolume = volume
                    
                    // Haptic feedback for success
                    if hapticFeedbackEnabled {
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    }
                    
                    // Show success message
                    alertMessage = "Saved: \(volume) mL of \(formulaType)"
                    showingAlert = true
                    isSubmitting = false
                }
                
                // Save last used formula type for Siri
                UserDefaults.standard.set(formulaType, forKey: "lastUsedFormulaType")
                
                // Donate to Siri for future voice commands (outside MainActor since it's async)
                let intent = LogFeedIntent()
                intent.volume = VolumeEntity(id: Int(volume) ?? 0)
                
                // Simplified donation
                Task {
                    // This will help Siri learn user patterns
                    try? await intent.donate()
                }
                
                // Update today's total if it's today (outside MainActor.run since it's async)
                if Calendar.current.isDateInToday(selectedDate) {
                    do {
                        let total = try await sheetsService.fetchTodayTotal()
                        await MainActor.run {
                            totalVolumeToday = total
                        }
                    } catch {
                        print("Error refreshing total: \(error)")
                    }
                }
            } catch {
                // Error - show on main thread
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showingAlert = true
                    isSubmitting = false
                    
                    // Error haptic
                    if hapticFeedbackEnabled {
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.error)
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
