import SwiftUI

struct SettingsView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    @AppStorage("spreadsheetId") private var spreadsheetId = ""
    @AppStorage("dailyVolumeGoal") private var dailyVolumeGoal = 1000
    @AppStorage("formulaTypes") private var formulaTypesData = ""
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("feedQuickVolumes") private var feedQuickVolumesData = "40,60,130,150"
    @AppStorage("pumpingQuickVolumes") private var pumpingQuickVolumesData = "130,140,150,170"
    @AppStorage("dragSpeed") private var dragSpeedRawValue = FeedConstants.DragSpeed.default.rawValue
    
    @State private var showingSpreadsheetIdAlert = false
    @State private var tempSpreadsheetId = ""
    @State private var showingFormulaTypesAlert = false
    @State private var tempFormulaTypes = ""
    @State private var showingSpreadsheetPicker = false
    @State private var showingCreateSheetAlert = false
    @State private var newSheetTitle = "Feed Tracking"
    @State private var isCreatingSheet = false
    @State private var showingFeedQuickVolumesAlert = false
    @State private var tempFeedQuickVolumes = ""
    @State private var showingPumpingQuickVolumesAlert = false
    @State private var tempPumpingQuickVolumes = ""
    
    // Default formula types
    private let defaultFormulaTypes = ["Breast milk", "Similac 360", "Emfamil Neuropro"]
    
    var dragSpeed: FeedConstants.DragSpeed {
        return FeedConstants.DragSpeed(rawValue: dragSpeedRawValue) ?? .default
    }
    
    var formulaTypes: [String] {
        if formulaTypesData.isEmpty {
            return defaultFormulaTypes
        }
        return formulaTypesData.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // MARK: - Computed Properties
    
    private var currentSheetStatusView: some View {
        Group {
            if !spreadsheetId.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(storageService.currentConfiguration?.name ?? "Untitled Sheet")
                            .font(.headline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    Text("Sheet ID: \(String(spreadsheetId.prefix(16)))...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No spreadsheet selected")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
    }
    
    private var dataStorageOptionsView: some View {
        VStack(spacing: 12) {
            // Create new (recommended)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create New Sheet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Recommended for new users")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    newSheetTitle = "Feed Tracking"
                    showingCreateSheetAlert = true
                }) {
                    if isCreatingSheet {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                            Text("Creating...")
                        }
                    } else {
                        Text("Create")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!storageService.isSignedIn || isCreatingSheet)
            }
            
            // Browse existing
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse Existing Sheets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Choose from your Google Drive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Browse") {
                    if storageService.isSignedIn {
                        showingSpreadsheetPicker = true
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!storageService.isSignedIn)
            }
            
            // Manual entry
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manual Entry")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Enter a spreadsheet ID directly")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Enter ID") {
                    tempSpreadsheetId = spreadsheetId
                    showingSpreadsheetIdAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section(header: Text("Account")) {
                    if !storageService.isSignedIn {
                        VStack(spacing: 12) {
                            Text("Sign in to save feeds")
                                .font(.headline)
                            Button(action: {
                                Task {
                                    try await storageService.signIn()
                                }
                            }) {
                                Label("Sign in with Google", systemImage: "person.badge.key")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Signed in as:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(storageService.userEmail ?? "Unknown")
                                    .font(.headline)
                            }
                            Spacer()
                            Button("Sign Out") {
                                try? storageService.signOut()
                                // Clear stored spreadsheet configuration when signing out
                                spreadsheetId = ""
                                UserDefaults.standard.removeObject(forKey: FeedConstants.UserDefaultsKeys.spreadsheetName)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Data Configuration
                Section(header: Text("Data Storage")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MiniLog saves your feeding data to Google Sheets for backup and multi-device access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Current spreadsheet status
                        HStack {
                            Text("Current Sheet:")
                                .font(.headline)
                            Spacer()
                        }
                        
                        currentSheetStatusView
                        
                        Divider()
                        
                        dataStorageOptionsView
                    }
                    .padding(.vertical, 8)
                }
                
                // Siri & Voice Commands
                Section(header: Text("Siri & Voice Commands")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.blue)
                            Text("Hey Siri")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Try saying:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \"Log 100 to MiniLog\"")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("• \"Add 150 to MiniLog\"")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("• \"Track 120 with MiniLog\"")
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("• \"Log feed 980 in MiniLog\"")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Uses your last selected formula type automatically.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.vertical, 4)
                }
                
                // App Settings
                Section(header: Text("App Settings")) {
                    // Daily Volume Goal
                    HStack {
                        Text("Daily Volume Goal")
                        Spacer()
                        TextField("Goal", value: $dailyVolumeGoal, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mL")
                            .foregroundColor(.secondary)
                    }
                    
                    // Formula Types
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Formula Types")
                            Spacer()
                            Button("Edit") {
                                tempFormulaTypes = formulaTypes.joined(separator: ", ")
                                showingFormulaTypesAlert = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(formulaTypes.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Haptic Feedback Toggle
                    Toggle("Enhanced Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    
                    if hapticFeedbackEnabled {
                        Text("Provides precise haptic clicks when adjusting volume with drag gesture")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Drag Speed Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume Drag Speed")
                            .font(.headline)
                        
                        Picker("Drag Speed", selection: $dragSpeedRawValue) {
                            ForEach(FeedConstants.DragSpeed.allCases, id: \.rawValue) { speed in
                                Text(speed.description).tag(speed.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Controls how fast the volume changes when dragging up/down on the volume field")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Feed Quick Volumes
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Feed Quick Volumes")
                            Spacer()
                            Button("Edit") {
                                tempFeedQuickVolumes = feedQuickVolumesData
                                showingFeedQuickVolumesAlert = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(feedQuickVolumesData.replacingOccurrences(of: ",", with: ", ") + " mL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Pumping Quick Volumes
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pumping Quick Volumes")
                            Spacer()
                            Button("Edit") {
                                tempPumpingQuickVolumes = pumpingQuickVolumesData
                                showingPumpingQuickVolumesAlert = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(pumpingQuickVolumesData.replacingOccurrences(of: ",", with: ", ") + " mL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // App Info
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(appBuild)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section(header: Text("Debug Tools")) {
                    NavigationLink(destination: DataCaptureView(storageService: storageService)) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Capture Test Data")
                                    .font(.headline)
                                Text("Record real API responses for unit testing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Edit Spreadsheet ID", isPresented: $showingSpreadsheetIdAlert) {
                TextField("Spreadsheet ID", text: $tempSpreadsheetId)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    spreadsheetId = tempSpreadsheetId
                    // Update the service with new spreadsheet ID
                    let config = StorageConfiguration(
                        identifier: tempSpreadsheetId,
                        name: "Current Spreadsheet",
                        provider: .googleSheets
                    )
                    try? storageService.updateConfiguration(config)
                }
            } message: {
                Text("Enter the Google Sheets ID from your spreadsheet URL")
            }
            .alert("Edit Formula Types", isPresented: $showingFormulaTypesAlert) {
                TextField("Formula Types", text: $tempFormulaTypes)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    formulaTypesData = tempFormulaTypes
                }
                Button("Reset to Default", role: .destructive) {
                    formulaTypesData = ""
                }
            } message: {
                Text("Enter formula types separated by commas")
            }
            .sheet(isPresented: $showingSpreadsheetPicker) {
                SpreadsheetPickerView(storageService: storageService)
            }
            .alert("Create New Sheet", isPresented: $showingCreateSheetAlert) {
                TextField("Sheet Name", text: $newSheetTitle)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    createNewSheet()
                }
            } message: {
                Text("This will create a new Google Sheet with the proper column headers for feed tracking.")
            }
            .alert("Edit Feed Quick Volumes", isPresented: $showingFeedQuickVolumesAlert) {
                TextField("Feed Quick Volumes", text: $tempFeedQuickVolumes)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    feedQuickVolumesData = tempFeedQuickVolumes
                }
                Button("Reset to Default", role: .destructive) {
                    feedQuickVolumesData = "40,60,130,150"
                }
            } message: {
                Text("Enter 4 volume amounts separated by commas (e.g., 40,60,130,150)")
            }
            .alert("Edit Pumping Quick Volumes", isPresented: $showingPumpingQuickVolumesAlert) {
                TextField("Pumping Quick Volumes", text: $tempPumpingQuickVolumes)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    pumpingQuickVolumesData = tempPumpingQuickVolumes
                }
                Button("Reset to Default", role: .destructive) {
                    pumpingQuickVolumesData = "130,140,150,170"
                }
            } message: {
                Text("Enter 4 volume amounts separated by commas (e.g., 130,140,150,170)")
            }
        }
    }
    
    private func createNewSheet() {
        isCreatingSheet = true
        
        Task {
            do {
                let newSheetId = try await storageService.createNewStorage(title: newSheetTitle)
                
                await MainActor.run {
                    // Update the spreadsheet ID
                    spreadsheetId = newSheetId
                    let config = StorageConfiguration(
                        identifier: newSheetId,
                        name: newSheetTitle,
                        provider: .googleSheets
                    )
                    try? storageService.updateConfiguration(config)
                    isCreatingSheet = false
                }
            } catch {
                await MainActor.run {
                    // Handle error - could show an error alert here
                    print("Error creating sheet: \(error)")
                    isCreatingSheet = false
                }
            }
        }
    }
}

#Preview {
    SettingsView(storageService: GoogleSheetsStorageService())
}
