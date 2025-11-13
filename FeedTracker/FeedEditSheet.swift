import SwiftUI
import Foundation

struct FeedEditSheet: View {
    let feed: FeedEntry
    @ObservedObject var storageService: GoogleSheetsStorageService
    let onSave: (FeedEntry) -> Void
    let onCancel: () -> Void
    
    @State private var selectedDate: Date
    @State private var selectedTime: Date
    @State private var volume: Int
    @State private var formulaType: String
    @State private var isWaste: Bool
    @State private var formulaTypes: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    
    init(feed: FeedEntry, storageService: GoogleSheetsStorageService, onSave: @escaping (FeedEntry) -> Void, onCancel: @escaping () -> Void) {
        self.feed = feed
        self.storageService = storageService
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state from the feed entry
        self._selectedDate = State(initialValue: feed.fullDate)
        self._selectedTime = State(initialValue: feed.fullDate)
        self._volume = State(initialValue: feed.actualVolume)  // Always positive
        self._formulaType = State(initialValue: feed.formulaType)
        self._isWaste = State(initialValue: feed.isWaste)      // True if volume was negative
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Feed Details")) {
                    // Date Picker
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    // Time Picker
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                    
                    // Volume Input with Feed/Waste Toggle
                    HStack {
                        Text("Volume")
                        Spacer()
                        
                        // Feed/Waste segmented control (matching main interface)
                        HStack(spacing: 0) {
                            Button(action: {
                                if isWaste {
                                    isWaste = false
                                }
                            }) {
                                Text("Feed")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isWaste ? .secondary : .white)
                                    .frame(width: 40, height: 26)
                                    .background(isWaste ? Color.clear : .accentColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if !isWaste {
                                    isWaste = true
                                }
                            }) {
                                Text("Waste")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isWaste ? .white : .secondary)
                                    .frame(width: 40, height: 26)
                                    .background(isWaste ? Color.orange : Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // Volume input on the right
                        HStack(spacing: 12) {
                            Button(action: decreaseVolume) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(isWaste ? .orange : .accentColor)
                            .frame(width: 32, height: 32)
                            
                            Text("\(volume)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(isWaste ? .orange : .accentColor)
                                .frame(minWidth: 50)
                            
                            Button(action: increaseVolume) {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(isWaste ? .orange : .accentColor)
                            .frame(width: 32, height: 32)
                        }
                    }
                    
                    // Formula Type Picker
                    Picker("Formula Type", selection: $formulaType) {
                        ForEach(formulaTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                }
            
            }
            .navigationTitle("Edit Feed Entry")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(.regularMaterial)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFeed()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadFormulaTypes()
        }
    }
    
    // MARK: - Actions
    
    private func decreaseVolume() {
        if volume > 5 {
            volume -= 5
        }
    }
    
    private func increaseVolume() {
        if volume < 500 {
            volume += 5
        }
    }
    
    
    private func loadFormulaTypes() {
        // Load formula types using the same approach as FeedEntryViewModel
        let formulaTypesData = UserDefaults.standard.string(forKey: FeedConstants.UserDefaultsKeys.formulaTypes) ?? ""
        
        if formulaTypesData.isEmpty {
            formulaTypes = FeedConstants.defaultFormulaTypes
        } else {
            formulaTypes = formulaTypesData.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        // Ensure current formula type is in the list
        if !formulaTypes.contains(formulaType) {
            formulaTypes.append(formulaType)
        }
    }
    
    private func saveFeed() {
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let combinedDate = calendar.date(from: combinedComponents) ?? Date()
        
        // Format date and time strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: combinedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: combinedDate)
        
        // Format volume and waste amount exactly like the main ViewModel
        // Convert Int to String first to match main ViewModel behavior
        let volumeString = "\(volume)"
        let volumeForStorage = isWaste ? "-\(volumeString)" : volumeString
        let wasteAmountForStorage = isWaste ? volumeString : "0"
        
        
        Task {
            do {
                try await storageService.updateFeedEntry(
                    feed,
                    newDate: dateString,
                    newTime: timeString,
                    newVolume: volumeForStorage,
                    newFormulaType: formulaType,
                    newWasteAmount: wasteAmountForStorage
                )
                
                await MainActor.run {
                    // Create updated feed entry for the callback
                    let updatedFeed = FeedEntry(
                        date: dateString,
                        time: timeString,
                        volume: isWaste ? -volume : volume,
                        formulaType: formulaType,
                        wasteAmount: isWaste ? volume : 0,
                        rowIndex: feed.rowIndex
                    )
                    
                    onSave(updatedFeed)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    // Handle error - could show an alert here
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let sampleFeed = FeedEntry(
        date: "8/26/2025",
        time: "2:30 PM",
        volume: 120,
        formulaType: "Enfamil",
        wasteAmount: 0,
        rowIndex: 5
    )
    
    return FeedEditSheet(
        feed: sampleFeed,
        storageService: GoogleSheetsStorageService(),
        onSave: { _ in },
        onCancel: { }
    )
}