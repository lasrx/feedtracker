import SwiftUI
import AppIntents
import Foundation

struct HorizontalNavigationView: View {
    @State private var currentPage: Int = 1 // Start at center (feed logging)
    @GestureState private var dragOffset: CGFloat = 0
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @StateObject private var sheetsService = GoogleSheetsService()
    @State private var pumpingViewTrigger: Int = 0
    @State private var feedHistoryViewTrigger: Int = 0
    @State private var pumpingHistoryViewTrigger: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left pane: Feed History
                FeedHistoryView(sheetsService: sheetsService, refreshTrigger: feedHistoryViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(0)
                
                // Center pane: Feed Logging (existing ContentView)
                FeedLoggingView(sheetsService: sheetsService)
                    .frame(width: geometry.size.width)
                    .tag(1)
                
                // Right pane: Pumping Logger
                PumpingView(sheetsService: sheetsService, refreshTrigger: pumpingViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(2)
                
                // Far right pane: Pumping History
                PumpingHistoryView(sheetsService: sheetsService, refreshTrigger: pumpingHistoryViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(3)
            }
            .offset(x: -CGFloat(currentPage) * geometry.size.width + dragOffset)
            .animation(.interpolatingSpring(stiffness: FeedConstants.springStiffness, damping: FeedConstants.springDamping), value: currentPage)
            .onChange(of: currentPage) { oldPage, newPage in
                print("HorizontalNavigationView: Page changed from \(oldPage) to \(newPage)")
                // Trigger data loading when navigating to specific views
                if newPage == 0 {
                    // Navigated to Feed History - trigger refresh
                    print("HorizontalNavigationView: Triggering Feed History refresh")
                    feedHistoryViewTrigger += 1
                } else if newPage == 2 {
                    // Navigated to Pumping View - trigger refresh
                    print("HorizontalNavigationView: Triggering Pumping View refresh")
                    pumpingViewTrigger += 1
                } else if newPage == 3 {
                    // Navigated to Pumping History - trigger refresh
                    print("HorizontalNavigationView: Triggering Pumping History refresh")
                    pumpingHistoryViewTrigger += 1
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = FeedConstants.swipeThreshold
                        let dragDistance = value.translation.width
                        
                        if dragDistance > threshold && currentPage > 0 {
                            // Swipe right - go to previous page
                            currentPage -= 1
                            // Navigation haptics removed per user feedback
                        } else if dragDistance < -threshold && currentPage < 3 {
                            // Swipe left - go to next page
                            currentPage += 1
                            // Navigation haptics removed per user feedback
                        }
                    }
            )
        }
        .clipped()
        .overlay(
            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: FeedConstants.pageIndicatorSpacing) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(FeedConstants.secondaryOpacity))
                            .frame(width: FeedConstants.pageIndicatorSize, height: FeedConstants.pageIndicatorSize)
                            .animation(.easeInOut(duration: FeedConstants.pageIndicatorAnimationDuration), value: currentPage)
                    }
                }
                .padding(.bottom, FeedConstants.pageIndicatorBottomPadding)
            }
        )
    }
}

// Refactored FeedLoggingView using shared components
struct FeedLoggingView: View {
    
    // MARK: - Dependencies
    @ObservedObject var sheetsService: GoogleSheetsService
    @StateObject private var viewModel: FeedEntryViewModel
    
    // MARK: - Initialization
    init(sheetsService: GoogleSheetsService) {
        self.sheetsService = sheetsService
        self._viewModel = StateObject(wrapping: FeedEntryViewModel(sheetsService: sheetsService))
    }
    
    // MARK: - Body
    var body: some View {
        // Use the shared FeedEntryForm component
        FeedEntryForm(
            viewModel: viewModel,
            sheetsService: sheetsService
        )
        .onAppear {
            // Ensure viewModel has the correct sheets service
            viewModel.updateSheetsService(sheetsService)
        }
    }
}


#Preview {
    HorizontalNavigationView()
}