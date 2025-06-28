import SwiftUI

/// Simplified ContentView using shared components and new storage abstraction
/// Reduced from 987 lines to ~70 lines through architectural refactor
struct ContentView: View {
    
    // MARK: - Dependencies
    @StateObject private var storageService = GoogleSheetsStorageService()
    @StateObject private var viewModel: FeedEntryViewModel
    
    // MARK: - Initialization
    init() {
        let storage = GoogleSheetsStorageService()
        self._storageService = StateObject(wrappedValue: storage)
        self._viewModel = StateObject(wrappedValue: FeedEntryViewModel(storageService: storage))
    }
    
    // MARK: - Body
    var body: some View {
        // Use the shared FeedEntryForm component
        NavigationView {
            FeedEntryForm(
                viewModel: viewModel,
                storageService: storageService
            )
        }
        .preferredColorScheme(nil) // Respects system dark mode setting
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
