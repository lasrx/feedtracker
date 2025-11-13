import SwiftUI
import Foundation

struct PumpingEditSheet: View {
    let session: PumpingEntry
    @ObservedObject var storageService: GoogleSheetsStorageService
    let onSave: (PumpingEntry) -> Void
    let onCancel: () -> Void
    
    @State private var selectedDate: Date
    @State private var selectedTime: Date
    @State private var volume: Int
    
    @Environment(\.dismiss) private var dismiss
    
    init(session: PumpingEntry, storageService: GoogleSheetsStorageService, onSave: @escaping (PumpingEntry) -> Void, onCancel: @escaping () -> Void) {
        self.session = session
        self.storageService = storageService
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state from the pumping session
        self._selectedDate = State(initialValue: session.fullDate)
        self._selectedTime = State(initialValue: session.fullDate)
        self._volume = State(initialValue: session.volume)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pumping Session Details")) {
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
                                .foregroundColor(.purple)
                            
                            Text("\(volume)")
                                .font(.title2)
                                .fontWeight(.medium)
                                .frame(minWidth: 50)
                            
                            Text("mL")
                                .foregroundColor(.secondary)
                            
                            Button("+", action: increaseVolume)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .navigationTitle("Edit Pumping Session")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .presentationBackground(.ultraThinMaterial)
            .presentationDetents([.medium])
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                }
            }
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
    
    private func saveSession() {
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
        
        // Create updated pumping session
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let updatedSession = PumpingEntry(
            date: dateFormatter.string(from: combinedDate),
            time: timeFormatter.string(from: combinedDate),
            volume: volume,
            rowIndex: session.rowIndex
        )
        
        onSave(updatedSession)
        dismiss()
    }
}

#Preview {
    let sampleSession = PumpingEntry(
        date: "8/26/2025",
        time: "2:30 PM",
        volume: 150,
        rowIndex: 3
    )
    
    return PumpingEditSheet(
        session: sampleSession,
        storageService: GoogleSheetsStorageService(),
        onSave: { _ in },
        onCancel: { }
    )
}