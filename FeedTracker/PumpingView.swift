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
        NavigationView {
            Form {
                // Sign-in prompt if not signed in
                if !storageService.isSignedIn {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "drop.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
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
                }
                
                // Today's Pumping Summary
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Today's Pumping", systemImage: "drop.triangle.fill")
                            .font(.headline)
                        
                        HStack(alignment: .bottom) {
                            Text("\(viewModel.totalVolumeToday) mL")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("pumped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar (using same goal as feeding for now)
                        ProgressView(value: viewModel.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(y: 1.5)
                            .accentColor(.purple)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                )
                
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
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            } else {
                                Image(systemName: "drop.triangle.fill")
                                Text("Log Pumping Session")
                            }
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isFormValid)
                    .accentColor(.purple)
                }
                
                Section(header: Text("Quick Actions")) {
                    // Common volume buttons for quick entry
                    VStack(spacing: 8) {
                        Text("Quick Volume Selection (mL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(viewModel.quickVolumes, id: \.self) { amount in
                                Button(action: {
                                    viewModel.selectQuickVolume(amount)
                                }) {
                                    Text("\(amount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 50, height: 40)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                            }
                        }
                        
                        Text("Tip: Swipe up/down on volume field to adjust")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
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