import SwiftUI

struct MySheetsPickerView: View {
    @ObservedObject var storageService: GoogleSheetsStorageService
    var onSelect: (StorageOption) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sheets: [StorageOption] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("My Sheets")
                .navigationBarTitleDisplayMode(.inline)
                .scrollContentBackground(.hidden)
                .presentationBackground(.ultraThinMaterial)
                .presentationDetents([.medium])
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            loadSheets()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading sheets...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    loadSheets()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if sheets.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.pulse)
                Text("No sheets found")
                    .font(.headline)
                Text("Create a new sheet from Settings to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    ForEach(sheets.indices, id: \.self) { index in
                        Button {
                            onSelect(sheets[index])
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "tablecells")
                                    .foregroundStyle(.green)
                                    .symbolRenderingMode(.hierarchical)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sheets[index].name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    if let modified = sheets[index].lastModified {
                                        Text(formattedDate(modified))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if storageService.currentConfiguration?.identifier == sheets[index].id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .symbolRenderingMode(.hierarchical)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadSheets() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let options = try await storageService.fetchAvailableStorageOptions()
                sheets = options
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// Formats an ISO 8601 date string to a short, readable format.
    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else { return isoString }

        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}

#Preview {
    MySheetsPickerView(storageService: GoogleSheetsStorageService()) { _ in }
}
