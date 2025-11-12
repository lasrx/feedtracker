import SwiftUI

struct SpreadsheetPickerView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    @AppStorage(FeedConstants.UserDefaultsKeys.spreadsheetId) private var spreadsheetId = ""
    
    @State private var spreadsheets: [StorageOption] = []
    @State private var allSpreadsheets: [StorageOption] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSpreadsheet: StorageOption?
    @State private var showingMore = false
    
    private let initialDisplayCount = 6
    
    @Environment(\.presentationMode) var presentationMode
    
    var displayedSpreadsheets: [StorageOption] {
        if showingMore {
            return allSpreadsheets
        } else {
            return Array(allSpreadsheets.prefix(initialDisplayCount))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                // Filter explanation
                Text("Showing spreadsheets with 'tracker' in the name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                contentView
            }
        }
        .navigationTitle("Select Spreadsheet")
        .onAppear {
            loadSpreadsheets()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else if spreadsheets.isEmpty {
            emptyStateView
        } else {
            spreadsheetListView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Loading your spreadsheets...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)
            Text("Error loading spreadsheets")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadSpreadsheets()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            Text("No Sheets Found")
                .font(.headline)
            Text("Create a new tracking sheet using the \"Create Sheet\" button in Settings, or refresh to browse existing sheets.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                loadSpreadsheets()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var spreadsheetListView: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Available Spreadsheets")) {
                    ForEach(displayedSpreadsheets) { spreadsheet in
                        SpreadsheetRow(
                            spreadsheet: spreadsheet,
                            isSelected: spreadsheet.id == spreadsheetId,
                            onSelect: { selectSpreadsheet(spreadsheet) }
                        )
                    }
                    
                    showMoreButtonView
                }
            }
            
            doneButtonView
        }
    }
    
    @ViewBuilder
    private var showMoreButtonView: some View {
        if !showingMore && allSpreadsheets.count > initialDisplayCount {
            Button(action: {
                showingMore = true
                updateDisplayedSheets()
            }) {
                HStack {
                    Image(systemName: "chevron.down")
                    Text("Show \(allSpreadsheets.count - initialDisplayCount) More Sheets")
                    Spacer()
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private var doneButtonView: some View {
        if !spreadsheetId.isEmpty {
            VStack(spacing: 8) {
                Text("Selected: \(getSelectedSheetName())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Select Sheet")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectSpreadsheet(_ spreadsheet: StorageOption) {
        selectedSpreadsheet = spreadsheet
        spreadsheetId = spreadsheet.id
        let config = StorageConfiguration(
            identifier: spreadsheet.id,
            name: spreadsheet.name,
            provider: spreadsheet.provider
        )
        try? storageService.updateConfiguration(config)
    }
    
    private func loadSpreadsheets() {
        isLoading = true
        errorMessage = nil
        showingMore = false
        
        Task {
            do {
                let fetchedSpreadsheets = try await storageService.fetchAvailableStorageOptions()
                await MainActor.run {
                    // Filter to only show spreadsheets with "tracker" in the name (case-insensitive)
                    self.allSpreadsheets = fetchedSpreadsheets.filter { spreadsheet in
                        spreadsheet.name.lowercased().contains("tracker")
                    }
                    self.updateDisplayedSheets()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Provide user-friendly error message for permission scenarios
                    if error.localizedDescription.contains("authentication") || error.localizedDescription.contains("permission") {
                        self.errorMessage = "Additional permissions needed to browse existing sheets. You can still create new sheets in Settings without this permission."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    private func updateDisplayedSheets() {
        spreadsheets = displayedSpreadsheets
    }
    
    private func getSelectedSheetName() -> String {
        if let selected = allSpreadsheets.first(where: { $0.id == spreadsheetId }) {
            return selected.displayName
        }
        return "Unknown Sheet"
    }
}

struct SpreadsheetRow: View {
    let spreadsheet: StorageOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spreadsheet.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack {
                        if let lastModified = spreadsheet.lastModified, !lastModified.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("Updated \(lastModified)")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                Text("Tracking sheet")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SpreadsheetPickerView(storageService: GoogleSheetsStorageService())
}