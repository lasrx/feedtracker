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
    @State private var wasteAmount: Int
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
        self._volume = State(initialValue: feed.actualVolume)
        self._formulaType = State(initialValue: feed.formulaType)
        self._wasteAmount = State(initialValue: feed.wasteAmount)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feed Details")) {
                    // Date Picker
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    // Time Picker
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                    
                    // Volume Input
                    HStack {
                        Text("Volume")
                        Spacer()
                        HStack {
                            Button("-", action: decreaseVolume)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.accentColor)
                            
                            Text("\(volume)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .frame(minWidth: 50)
                            
                            Text("mL")
                                .foregroundColor(.secondary)
                            
                            Button("+", action: increaseVolume)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // Formula Type Picker
                    Picker("Formula Type", selection: $formulaType) {
                        ForEach(formulaTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Waste Amount (if applicable)
                    if wasteAmount > 0 {
                        HStack {
                            Text("Waste Amount")
                            Spacer()
                            HStack {
                                Button("-", action: decreaseWaste)
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundColor(.orange)
                                
                                Text("\(wasteAmount)")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .frame(minWidth: 50)
                                
                                Text("mL")
                                    .foregroundColor(.secondary)
                                
                                Button("+", action: increaseWaste)
                                    .buttonStyle(PlainButtonStyle())
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Add Waste Entry") {
                        if wasteAmount == 0 {
                            wasteAmount = 5
                        }
                    }
                    .disabled(wasteAmount > 0)
                    
                    if wasteAmount > 0 {
                        Button("Remove Waste Entry") {
                            wasteAmount = 0
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Edit Feed Entry")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func decreaseWaste() {
        if wasteAmount > 5 {
            wasteAmount -= 5
        }
    }
    
    private func increaseWaste() {
        if wasteAmount < 200 {
            wasteAmount += 5
        }
    }
    
    private func loadFormulaTypes() {
        // Load formula types from UserDefaults or use defaults
        formulaTypes = UserDefaults.standard.stringArray(forKey: "formulaTypes") ?? 
            FeedConstants.defaultFormulaTypes
        
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
        
        // Create updated feed entry
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let updatedFeed = FeedEntry(
            date: dateFormatter.string(from: combinedDate),
            time: timeFormatter.string(from: combinedDate),
            volume: volume,
            formulaType: formulaType,
            wasteAmount: wasteAmount,
            rowIndex: feed.rowIndex
        )
        
        onSave(updatedFeed)
        dismiss()
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