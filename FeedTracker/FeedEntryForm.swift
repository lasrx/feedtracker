import SwiftUI
import GoogleSignIn

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
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            }

            // Today's Summary Card
            todaySummarySection
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            
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
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(storageService: storageService)
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
                    .symbolRenderingMode(.hierarchical)
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
                    .symbolRenderingMode(.hierarchical)
                
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
                .fill(.regularMaterial)
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
            
            // Feed/Waste segmented control
            HStack(spacing: 0) {
                Button(action: {
                    if viewModel.isWaste {
                        viewModel.toggleWasteMode()
                    }
                }) {
                    Text("Feed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isWaste ? .secondary : .white)
                        .frame(width: 40, height: 26)
                        .background(viewModel.isWaste ? Color.clear : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if !viewModel.isWaste {
                        viewModel.toggleWasteMode()
                    }
                }) {
                    Text("Waste")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isWaste ? .white : .secondary)
                        .frame(width: 40, height: 26)
                        .background(viewModel.isWaste ? Color.orange : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
            Spacer()
            
            // Volume input on the right
            HStack {
                if viewModel.isDragging {
                    Text("\(viewModel.dragStartVolume)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(viewModel.isWaste ? .orange : .accentColor)
                        .frame(
                            width: FeedConstants.dragVolumeDisplayWidth,
                            height: FeedConstants.dragVolumeDisplayHeight
                        )
                        .background((viewModel.isWaste ? Color.orange : Color.accentColor).opacity(FeedConstants.accentOpacity))
                        .cornerRadius(8)
                } else {
                    TextField("0", text: $viewModel.volume)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: FeedConstants.volumeTextFieldWidth)
                        .font(.system(size: 17))
                        .foregroundColor(viewModel.isWaste ? .orange : .primary)
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
                            .tint(viewModel.isWaste ? .orange : .accentColor)
                        Text("Saving...")
                    } else {
                        Image(systemName: viewModel.isWaste ? "trash.circle.fill" : "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                        Text(viewModel.isWaste ? "Log Waste Entry" : "Add Feed Entry")
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(viewModel.isFormValid ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: FeedConstants.submitButtonHeight)
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(viewModel.isFormValid ?
                                      (viewModel.isWaste ? Color.orange : Color.accentColor).opacity(0.7) :
                                      Color.gray.opacity(0.15))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 25)
                                .strokeBorder(viewModel.isFormValid ?
                                              (viewModel.isWaste ? Color.orange : Color.accentColor).opacity(0.5) :
                                              Color.secondary.opacity(0.2), lineWidth: 1)
                        }
                        .shadow(color: viewModel.isFormValid ?
                                (viewModel.isWaste ? Color.orange : Color.accentColor).opacity(0.3) :
                                Color.clear, radius: 8, y: 4)
                }
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isFormValid)
            .scaleEffect(viewModel.isSubmitting ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isSubmitting)
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        Section(header: Text("Quick Actions")) {
            VStack(spacing: 12) {
                Text("Quick Volume Selection (mL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    // Quick volume buttons
                    ForEach(viewModel.quickVolumes, id: \.self) { amount in
                        Button(action: {
                            viewModel.selectQuickVolume(amount)
                        }) {
                            Text(amount)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: FeedConstants.quickVolumeButtonHeight)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.accentColor.opacity(0.7))
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
                                        }
                                        .shadow(color: Color.accentColor.opacity(0.2), radius: 4, y: 2)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Tip: Swipe up/down on volume field to adjust")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FeedEntryForm(
            viewModel: FeedEntryViewModel(storageService: GoogleSheetsStorageService()),
            storageService: GoogleSheetsStorageService()
        )
    }
}