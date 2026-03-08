import SwiftUI

struct SettingsView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    @AppStorage(FeedConstants.UserDefaultsKeys.spreadsheetId) private var spreadsheetId = ""
    @AppStorage(FeedConstants.UserDefaultsKeys.dailyVolumeGoal) private var dailyVolumeGoal = 1000
    @AppStorage(FeedConstants.UserDefaultsKeys.formulaTypes) private var formulaTypesData = ""
    @AppStorage(FeedConstants.UserDefaultsKeys.hapticFeedbackEnabled) private var hapticFeedbackEnabled = true
    @AppStorage(FeedConstants.UserDefaultsKeys.feedQuickVolumes) private var feedQuickVolumesData = "40,60,130,150"
    @AppStorage(FeedConstants.UserDefaultsKeys.pumpingQuickVolumes) private var pumpingQuickVolumesData = "130,140,150,170"
    @AppStorage("dragSpeed") private var dragSpeedRawValue = FeedConstants.DragSpeed.default.rawValue
    
    @State private var showingFormulaTypesEditor = false
    @State private var showingCreateSheetAlert = false
    @State private var newSheetTitle = "Feed Tracking"
    @State private var isCreatingSheet = false
    @State private var showingFeedQuickVolumesEditor = false
    @State private var showingPumpingQuickVolumesEditor = false
    @State private var showingMySheetsPicker = false
    @State private var showingGooglePicker = false
    
    // Default formula types
    private let defaultFormulaTypes = FeedConstants.defaultFormulaTypes
    
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
                            .foregroundStyle(.green)
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.bounce, value: spreadsheetId)
                        Text(storageService.currentConfiguration?.name ?? "Untitled Sheet")
                            .font(.headline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    Text("Sheet ID: \(String(spreadsheetId.prefix(16)))...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .symbolRenderingMode(.hierarchical)
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
                        .foregroundStyle(.secondary)
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
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .disabled(!storageService.isSignedIn || isCreatingSheet)
            }

            // Browse my sheets
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Sheets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Browse your MiniLog sheets")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Browse") {
                    showingMySheetsPicker = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!storageService.isSignedIn)
            }

            // Find shared sheet via Google Picker
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find Shared Sheet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Search all sheets shared with you")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Search") {
                    showingGooglePicker = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!storageService.isSignedIn)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                            .buttonBorderShape(.capsule)
                            .symbolEffect(.bounce, value: storageService.isSignedIn)
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Signed in as:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                        
                        // Current spreadsheet status
                        HStack {
                            Text("Current Sheet:")
                                .font(.headline)
                            Spacer()
                        }
                        
                        currentSheetStatusView

                        if !spreadsheetId.isEmpty {
                            Button(action: shareTracker) {
                                Label("Share Tracker", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        Divider()

                        dataStorageOptionsView

                        Divider()

                        DisclosureGroup("How to share a tracker") {
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Owner:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Tap Share Tracker to send an invite link to your co-caregiver.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Receiver:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("1. Install MiniLog and sign in with Google")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("2. Open the invite link, or tap Find Shared Sheet")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Important:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("The owner must also share the spreadsheet in Google Sheets for write access.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }

                // Siri & Voice Commands
                Section(header: Text("Siri & Voice Commands")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundStyle(.blue)
                                .symbolRenderingMode(.hierarchical)
                            Text("Hey Siri")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Try saying:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \"Log 100 to MiniLog\"")
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Text("• \"Add 150 to MiniLog\"")
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Text("• \"Track 120 with MiniLog\"")
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Text("• \"Log feed 980 in MiniLog\"")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        
                        Text("Uses your last selected formula type automatically.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                    }
                    
                    // Formula Types
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Formula Types")
                            Spacer()
                            Button("Edit") {
                                showingFormulaTypesEditor = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(formulaTypes.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Haptic Feedback Toggle
                    Toggle("Enhanced Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    
                    if hapticFeedbackEnabled {
                        Text("Provides precise haptic clicks when adjusting volume with drag gesture")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Feed Quick Volumes
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Feed Quick Volumes")
                            Spacer()
                            Button("Edit") {
                                showingFeedQuickVolumesEditor = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(feedQuickVolumesData.replacingOccurrences(of: ",", with: ", ") + " mL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    // Pumping Quick Volumes
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pumping Quick Volumes")
                            Spacer()
                            Button("Edit") {
                                showingPumpingQuickVolumesEditor = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(pumpingQuickVolumesData.replacingOccurrences(of: ",", with: ", ") + " mL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // App Info
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(appBuild)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section(header: Text("Debug Tools")) {
                    NavigationLink(destination: DataCaptureView(storageService: storageService)) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Capture Test Data")
                                    .font(.headline)
                                Text("Record real API responses for unit testing")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .presentationBackground(.ultraThinMaterial)
            .presentationDetents([.large])
            .sheet(isPresented: $showingFormulaTypesEditor) {
                FormulaTypesEditorView(formulaTypesData: $formulaTypesData)
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
            .sheet(isPresented: $showingFeedQuickVolumesEditor) {
                QuickVolumesEditorView(
                    title: "Feed Quick Volumes",
                    unit: "mL",
                    quickVolumesData: $feedQuickVolumesData
                )
            }
            .sheet(isPresented: $showingPumpingQuickVolumesEditor) {
                QuickVolumesEditorView(
                    title: "Pumping Quick Volumes",
                    unit: "mL",
                    quickVolumesData: $pumpingQuickVolumesData
                )
            }
            .sheet(isPresented: $showingMySheetsPicker) {
                MySheetsPickerView(storageService: storageService) { option in
                    spreadsheetId = option.id
                    let config = StorageConfiguration(
                        identifier: option.id,
                        name: option.name,
                        provider: .googleSheets
                    )
                    try? storageService.updateConfiguration(config)
                }
            }
            .sheet(isPresented: $showingGooglePicker) {
                GooglePickerSheet(
                    storageService: storageService,
                    preselectedFileIds: nil
                ) { fileId, fileName in
                    storageService.completePickerAuthorization(fileId: fileId, fileName: fileName)
                }
            }
        }
    }
    
    private func shareTracker() {
        let sheetName = storageService.currentConfiguration?.name ?? "Feed Tracking"
        let encodedName = sheetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sheetName
        let deepLink = "minilog://connect?id=\(spreadsheetId)&name=\(encodedName)"
        let shareText = "Join my baby tracker \"\(sheetName)\" on MiniLog!\n\n\(deepLink)"

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            // Walk to the topmost presented VC
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            // iPad popover support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            topVC.present(activityVC, animated: true)
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
