import SwiftUI
import AppIntents
import Foundation

struct PumpingView: View {
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var volume = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var totalVolumeToday: Int = 0
    @State private var isDragging = false
    @State private var dragStartVolume: Int = 0
    @State private var isSubmitting = false
    @State private var lastHapticVolume: Int = 0
    
    @ObservedObject var sheetsService: GoogleSheetsService
    let refreshTrigger: Int
    @AppStorage("dailyVolumeGoal") private var dailyVolumeGoal = 1000
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    let quickVolumes = ["20", "40", "60", "80"]
    
    // Dark mode aware colors
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                // Sign-in prompt if not signed in
                if !sheetsService.isSignedIn {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "drop.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Sign in to save pumping sessions")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text("Tap the settings gear to sign in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Today's Pumping Summary
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Today's Pumping", systemImage: "drop.triangle.fill")
                            .font(.headline)
                        
                        HStack(alignment: .bottom) {
                            Text("\(totalVolumeToday) mL")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("pumped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar (using same goal as feeding for now)
                        ProgressView(value: Double(totalVolumeToday), total: Double(dailyVolumeGoal))
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 1.5)
                            .accentColor(.purple)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                )
                
                Section(header: Text("Pumping Session")) {
                    // Date Picker
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Time Picker
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Volume Entry with Drag Gesture
                    HStack {
                        Text("Volume")
                        Spacer()
                        HStack {
                            if isDragging {
                                Text("\(dragStartVolume)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.purple)
                                    .frame(width: 120, height: 60)
                                    .background(Color.purple.opacity(0.1))
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
                                    
                                    // Same sensitivity as feed logging: 2.5 pixels per 1 mL
                                    let change = Int(value.translation.height / -2.5)
                                    let originalStart = Int(volume) ?? 0
                                    let newVolume = max(0, min(999, originalStart + change))
                                    
                                    // Update dragStartVolume for visual feedback during drag
                                    dragStartVolume = newVolume
                                    
                                    // Haptic feedback on 5mL boundaries
                                    if hapticFeedbackEnabled && newVolume % 5 == 0 && newVolume != lastHapticVolume {
                                        let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = newVolume % 25 == 0 ? .heavy : .medium
                                        UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred()
                                        lastHapticVolume = newVolume
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    volume = "\(dragStartVolume)"
                                    if hapticFeedbackEnabled {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }
                        )
                    }
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
                                Image(systemName: "drop.triangle.fill")
                                Text("Log Pumping Session")
                            }
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(volume.isEmpty || !sheetsService.isSignedIn || isSubmitting)
                    .accentColor(.purple)
                }
                
            }
            .navigationTitle("Pumping")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Pumping Session"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    volume = ""
                })
            }
            .onAppear {
                print("PumpingView: onAppear called")
                loadTodayTotal()
            }
            .onChange(of: refreshTrigger) { _, _ in
                print("PumpingView: refreshTrigger changed, loading data")
                loadTodayTotal()
            }
            .onChange(of: sheetsService.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    loadTodayTotal()
                } else {
                    totalVolumeToday = 0
                }
            }
            .refreshable {
                await loadTodayTotalAsync()
            }
        }
        .preferredColorScheme(nil)
    }
    
    private func loadTodayTotal() {
        print("PumpingView: loadTodayTotal called, isSignedIn: \(sheetsService.isSignedIn)")
        guard sheetsService.isSignedIn else { 
            print("PumpingView: Not signed in, skipping load")
            return 
        }
        
        Task {
            do {
                print("PumpingView: Calling fetchTodayPumpingTotal...")
                let total = try await sheetsService.fetchTodayPumpingTotal()
                print("PumpingView: Received pumping total: \(total)mL")
                await MainActor.run {
                    totalVolumeToday = total
                    print("PumpingView: Updated UI with pumping total: \(totalVolumeToday)mL")
                }
            } catch {
                print("Error loading today's pumping total: \(error)")
            }
        }
    }
    
    private func loadTodayTotalAsync() async {
        guard sheetsService.isSignedIn else { return }
        
        do {
            let total = try await sheetsService.fetchTodayPumpingTotal()
            await MainActor.run {
                totalVolumeToday = total
            }
        } catch {
            print("Error loading today's pumping total: \(error)")
        }
    }
    
    private func submitEntry() {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: selectedTime)
        
        Task {
            do {
                try await sheetsService.appendPumpingRow(
                    date: dateString,
                    time: timeString,
                    volume: volume
                )
                
                await MainActor.run {
                    alertMessage = "Saved: \(volume) mL pumping session"
                    showingAlert = true
                    isSubmitting = false
                    
                    if hapticFeedbackEnabled {
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    }
                    
                    // Refresh today's total
                    loadTodayTotal()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showingAlert = true
                    isSubmitting = false
                    
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
    PumpingView(sheetsService: GoogleSheetsService(), refreshTrigger: 0)
}