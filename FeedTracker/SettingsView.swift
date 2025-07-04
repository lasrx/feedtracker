import SwiftUI

struct SettingsView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    @AppStorage("spreadsheetId") private var spreadsheetId = ""
    @AppStorage("dailyVolumeGoal") private var dailyVolumeGoal = 1000
    @AppStorage("formulaTypes") private var formulaTypesData = ""
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("feedQuickVolumes") private var feedQuickVolumesData = "40,60,130,150"
    @AppStorage("pumpingQuickVolumes") private var pumpingQuickVolumesData = "130,140,150,170"
    
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
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Data Configuration
                Section(header: Text("Data Configuration")) {
                    // Spreadsheet Selection
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Active Spreadsheet")
                            Spacer()
                            Button("Select") {
                                if storageService.isSignedIn {
                                    showingSpreadsheetPicker = true
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(!storageService.isSignedIn)
                        }
                        
                        if !spreadsheetId.isEmpty {
                            Text(String(spreadsheetId.prefix(20)) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No spreadsheet selected")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        // Create new sheet option
                        HStack {
                            Text("Create new tracking sheet:")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                                    Text("Create Sheet")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(!storageService.isSignedIn || isCreatingSheet)
                        }
                        
                        // Manual entry option
                        HStack {
                            Text("Or enter existing spreadsheet ID:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Manual Entry") {
                                tempSpreadsheetId = spreadsheetId
                                showingSpreadsheetIdAlert = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
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
