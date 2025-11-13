import SwiftUI
import Foundation

struct HorizontalNavigationView: View {
    @State private var currentPage: Int = 1 // Start at center (feed logging)
    @GestureState private var dragOffset: CGFloat = 0
    @AppStorage(FeedConstants.UserDefaultsKeys.hapticFeedbackEnabled) private var hapticFeedbackEnabled = true
    @StateObject private var storageService = GoogleSheetsStorageService()
    @State private var pumpingViewTrigger: Int = 0
    @State private var feedHistoryViewTrigger: Int = 0
    @State private var pumpingHistoryViewTrigger: Int = 0
    
    #if DEBUG
    @StateObject private var dataCaptureService = DataCaptureService()
    #endif
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left pane: Feed History
                FeedHistoryView(storageService: storageService, refreshTrigger: feedHistoryViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(0)
                
                // Center pane: Feed Logging (existing ContentView)
                FeedLoggingView(storageService: storageService)
                    .frame(width: geometry.size.width)
                    .tag(1)
                
                // Right pane: Pumping Logger
                PumpingView(storageService: storageService, refreshTrigger: pumpingViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(2)
                
                // Far right pane: Pumping History
                PumpingHistoryView(storageService: storageService, refreshTrigger: pumpingHistoryViewTrigger)
                    .frame(width: geometry.size.width)
                    .tag(3)
            }
            .offset(x: -CGFloat(currentPage) * geometry.size.width + dragOffset)
            .animation(.interpolatingSpring(stiffness: FeedConstants.springStiffness, damping: FeedConstants.springDamping), value: currentPage)
            .onChange(of: currentPage) { oldPage, newPage in
                // Trigger data loading when navigating to specific views
                if newPage == 0 {
                    feedHistoryViewTrigger += 1
                } else if newPage == 2 {
                    pumpingViewTrigger += 1
                } else if newPage == 3 {
                    pumpingHistoryViewTrigger += 1
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .updating($dragOffset) { value, state, _ in
                        // Require strongly horizontal gestures to avoid interfering with volume drag
                        // Volume drag is typically more vertical or diagonal, navigation is horizontal
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)

                        // Absolute exclusion: if vertical movement > 15px, this is likely volume adjustment
                        let isLikelyVolumeGesture = verticalDistance > 15
                        let isStronglyHorizontal = horizontalDistance > verticalDistance * 3.0
                        let isLongEnough = horizontalDistance > 30

                        if isStronglyHorizontal && isLongEnough && !isLikelyVolumeGesture {
                            // Use full translation for natural feel (no dead-zone subtraction)
                            state = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let threshold = FeedConstants.swipeThreshold
                        let dragDistance = value.translation.width
                        // Require very horizontal swipes (3:1 ratio) to avoid volume input conflicts
                        let isStronglyHorizontal = abs(value.translation.width) > abs(value.translation.height) * 3.0

                        // Only navigate if this is clearly a horizontal swipe
                        if isStronglyHorizontal && abs(dragDistance) > threshold {
                            if dragDistance > threshold && currentPage > 0 {
                                currentPage -= 1
                            } else if dragDistance < -threshold && currentPage < 3 {
                                currentPage += 1
                            }
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
        #if DEBUG
        .onAppear {
            // Connect data capture service to storage service in debug builds
            storageService.dataCaptureService = dataCaptureService
        }
        #endif
    }
}

// Refactored FeedLoggingView using shared components
struct FeedLoggingView: View {
    
    // MARK: - Dependencies
    @ObservedObject var storageService: GoogleSheetsStorageService
    @StateObject private var viewModel: FeedEntryViewModel
    
    // MARK: - Initialization
    init(storageService: GoogleSheetsStorageService) {
        self.storageService = storageService
        self._viewModel = StateObject(wrappedValue: FeedEntryViewModel(storageService: storageService))
    }
    
    // MARK: - Body
    var body: some View {
        // Use the shared FeedEntryForm component wrapped in NavigationStack
        NavigationStack {
            FeedEntryForm(
                viewModel: viewModel,
                storageService: storageService
            )
        }
    }
}


#Preview {
    HorizontalNavigationView()
}