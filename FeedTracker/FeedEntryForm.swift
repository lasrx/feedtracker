import SwiftUI
import GoogleSignIn
import AppIntents

/// Shared UI component for feed entry forms
/// Eliminates code duplication between ContentView and FeedLoggingView
struct FeedEntryForm: View {
    
    // MARK: - Dependencies
    @StateObject var viewModel: FeedEntryViewModel
    @ObservedObject var storageService: GoogleSheetsStorageService
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Body
    var body: some View {
        Form {
            // Sign-in prompt if not signed in
            if !storageService.isSignedIn {
                signInPromptSection
            }
            
            // Today's Summary Card
            todaySummarySection
            
            // Feed Details Form
            feedDetailsSection
            
            // Submit Button
            submitButtonSection
            
            // Quick Actions
            quickActionsSection
        }
        .navigationTitle("MiniLog")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.showSettings) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
        }
        .alert("Feed Entry", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel, action: viewModel.dismissAlert)
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            viewModel.loadTodayTotal()
        }
        .onChange(of: storageService.isSignedIn) { _, isSignedIn in
            viewModel.handleSignInStatusChange(isSignedIn: isSignedIn)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.handleAppWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.handleAppDidEnterBackground()
        }
        .refreshable {
            await viewModel.loadTodayTotalAsync()
        }
    }
    
    // MARK: - Sign-in Prompt Section
    
    private var signInPromptSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "person.badge.key")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Sign in to Google to save feeds")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Tap the settings gear above to sign in")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Today's Summary Section
    
    private var todaySummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Label("Today's Feed Total", systemImage: "chart.bar.fill")
                    .font(.headline)
                
                HStack(alignment: .bottom) {
                    Text("\(viewModel.totalVolumeToday) mL")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text("/ \(viewModel.dailyVolumeGoal) mL goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                ProgressView(value: viewModel.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: FeedConstants.progressBarScaleY)
                
                if let lastTime = viewModel.lastFeedTime {
                    let timeAgo = RelativeTimeFormatter.shared.string(from: lastTime)
                    Text("Last feed: \(timeAgo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }
    
    // MARK: - Feed Details Section
    
    private var feedDetailsSection: some View {
        Section(header: Text("Feed Details")) {
            // Date Picker
            DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .frame(minHeight: FeedConstants.minimumTapTargetHeight)
            
            // Time Picker
            DatePicker("Time", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .frame(minHeight: FeedConstants.minimumTapTargetHeight)
            
            // Volume with swipe gesture
            volumeInputRow
            
            // Formula Type Picker
            Picker("Formula Type", selection: $viewModel.formulaType) {
                ForEach(viewModel.formulaTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(minHeight: FeedConstants.minimumTapTargetHeight)
        }
    }
    
    // MARK: - Volume Input Row
    
    private var volumeInputRow: some View {
        HStack {
            Text("Volume")
            Spacer()
            HStack {
                if viewModel.isDragging {
                    Text("\(viewModel.dragStartVolume)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(
                            width: FeedConstants.dragVolumeDisplayWidth,
                            height: FeedConstants.dragVolumeDisplayHeight
                        )
                        .background(Color.accentColor.opacity(FeedConstants.accentOpacity))
                        .cornerRadius(8)
                } else {
                    TextField("0", text: $viewModel.volume)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: FeedConstants.volumeTextFieldWidth)
                        .font(.system(size: 17))
                }
                
                Text("mL")
                    .foregroundColor(.secondary)
            }
            .highPriorityGesture(volumeDragGesture)
        }
        .frame(minHeight: FeedConstants.minimumTapTargetHeight)
    }
    
    // MARK: - Volume Drag Gesture
    
    private var volumeDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !viewModel.isDragging {
                    viewModel.startVolumeDrag()
                }
                viewModel.updateVolumeDrag(translation: value.translation)
            }
            .onEnded { _ in
                viewModel.endVolumeDrag()
            }
    }
    
    // MARK: - Submit Button Section
    
    private var submitButtonSection: some View {
        Section {
            Button(action: viewModel.submitEntry) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        Text("Saving...")
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Feed Entry")
                    }
                }
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .frame(height: FeedConstants.submitButtonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isFormValid)
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        Section(header: Text("Quick Actions")) {
            VStack(spacing: 8) {
                Text("Quick Volume Selection (mL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: FeedConstants.pageIndicatorSpacing) {
                    // Quick volume buttons
                    ForEach(viewModel.quickVolumes, id: \.self) { amount in
                        Button(action: {
                            viewModel.selectQuickVolume(amount)
                        }) {
                            Text(amount)
                                .font(.system(size: 16, weight: .medium))
                                .frame(
                                    width: FeedConstants.quickVolumeButtonWidth,
                                    height: FeedConstants.quickVolumeButtonHeight
                                )
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Dynamic "Last" button
                    if let lastVolume = viewModel.lastFeedVolume {
                        Button(action: viewModel.selectLastVolume) {
                            Text(lastVolume)
                                .font(.system(size: 16, weight: .medium))
                                .frame(
                                    width: FeedConstants.quickVolumeButtonWidth,
                                    height: FeedConstants.quickVolumeButtonHeight
                                )
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
                
                Text("Tip: Swipe up/down on volume field to adjust")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        FeedEntryForm(
            viewModel: FeedEntryViewModel(storageService: GoogleSheetsStorageService()),
            storageService: GoogleSheetsStorageService()
        )
    }
}