import SwiftUI

/// Simplified ContentView using shared components
/// Reduced from 987 lines to ~70 lines through architectural refactor
struct ContentView: View {
    
    // MARK: - Dependencies
    @StateObject private var sheetsService = GoogleSheetsService()
    @StateObject private var viewModel = FeedEntryViewModel(sheetsService: GoogleSheetsService())
    
    // MARK: - Body
    var body: some View {
        // Use the shared FeedEntryForm component
        NavigationView {
            FeedEntryForm(
                viewModel: viewModel,
                sheetsService: sheetsService
            )
        }
        .preferredColorScheme(nil) // Respects system dark mode setting
        .onAppear {
            // Sync the sheets services - this is a temporary approach
            // In a production app, we'd use dependency injection
            viewModel.updateSheetsService(sheetsService)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
