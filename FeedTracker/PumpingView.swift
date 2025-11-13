import SwiftUI
import Foundation

struct PumpingView: View {
    
    // MARK: - Dependencies
    @StateObject private var viewModel: PumpingEntryViewModel
    @ObservedObject var storageService: GoogleSheetsStorageService
    let refreshTrigger: Int
    
    // MARK: - Initialization
    init(storageService: GoogleSheetsStorageService, refreshTrigger: Int) {
        self.storageService = storageService
        self.refreshTrigger = refreshTrigger
        self._viewModel = StateObject(wrappedValue: PumpingEntryViewModel(storageService: storageService))
    }
    
    // Dark mode aware colors
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            Form {
                // Sign-in prompt if not signed in
                if !storageService.isSignedIn {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "drop.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                                .symbolRenderingMode(.hierarchical)
                            Text("Sign in to save pumping sessions")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text("Tap the settings gear to sign in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }

                // Today's Pumping Summary
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Today's Pumping", systemImage: "drop.triangle.fill")
                            .font(.headline)
                            .symbolRenderingMode(.hierarchical)
                        
                        HStack(alignment: .bottom) {
                            Text("\(viewModel.totalVolumeToday) mL")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("pumped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar with glass gradient
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.regularMaterial)
                                    .frame(height: 8)

                                // Progress fill with gradient
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(viewModel.progressPercentage), height: 8)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 4, y: 2)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                
                Section(header: Text("Pumping Session")) {
                    // Date Picker
                    DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Time Picker
                    DatePicker("Time", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .frame(minHeight: 44)
                    
                    // Volume Entry with Drag Gesture
                    HStack {
                        Text("Volume")
                        Spacer()
                        HStack {
                            if viewModel.isDragging {
                                Text("\(viewModel.dragStartVolume)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.purple)
                                    .frame(width: 120, height: 60)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                            } else {
                                TextField("0", text: $viewModel.volume)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .font(.system(size: 17))
                            }
                            
                            Text("mL")
                                .foregroundColor(.secondary)
                        }
                        .highPriorityGesture(volumeDragGesture)
                    }
                    .frame(minHeight: 44)
                }
                
                Section {
                    Button(action: viewModel.submitEntry) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.purple)
                                Text("Saving...")
                            } else {
                                Image(systemName: "drop.triangle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                Text("Log Pumping Session")
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.isFormValid ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.regularMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(viewModel.isFormValid ?
                                              Color.purple.opacity(0.7) :
                                              Color.gray.opacity(0.15))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 25)
                                        .strokeBorder(viewModel.isFormValid ?
                                                      Color.purple.opacity(0.5) :
                                                      Color.secondary.opacity(0.2), lineWidth: 1)
                                }
                                .shadow(color: viewModel.isFormValid ?
                                        Color.purple.opacity(0.3) :
                                        Color.clear, radius: 8, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isFormValid)
                    .scaleEffect(viewModel.isSubmitting ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isSubmitting)
                }
                
                Section {
                    // Common volume buttons for quick entry
                    VStack(spacing: 12) {
                        Text("Quick Volume Selection (mL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            ForEach(viewModel.quickVolumes, id: \.self) { amount in
                                Button(action: {
                                    viewModel.selectQuickVolume(amount)
                                }) {
                                    Text("\(amount)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.regularMaterial)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.purple.opacity(0.7))
                                                }
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(Color.purple.opacity(0.5), lineWidth: 1)
                                                }
                                                .shadow(color: Color.purple.opacity(0.2), radius: 4, y: 2)
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
            .navigationTitle("Pumping")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Pumping Session", isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel, action: viewModel.dismissAlert)
            } message: {
                Text(viewModel.alertMessage)
            }
            .onAppear {
                #if DEBUG
                print("PumpingView: onAppear called")
                #endif
                viewModel.loadTodayTotal()
            }
            .onChange(of: refreshTrigger) { _, _ in
                #if DEBUG
                print("PumpingView: refreshTrigger changed, loading data")
                #endif
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
        .preferredColorScheme(nil)
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
}

// MARK: - Preview
#Preview {
    PumpingView(storageService: GoogleSheetsStorageService(), refreshTrigger: 0)
}