import SwiftUI

struct QuickVolumesEditorView: View {
    let title: String
    let unit: String
    @Binding var quickVolumesData: String
    @State private var volumes: [Int] = []
    @State private var showingAddAlert = false
    @State private var newVolumeText = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(volumes.indices, id: \.self) { index in
                        HStack {
                            Text("\(volumes[index]) \(unit)")
                                .font(.body)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .onDelete(perform: deleteVolume)
                    .onMove(perform: moveVolume)
                    
                    // Add New Button
                    Button(action: {
                        newVolumeText = ""
                        showingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Volume")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text(title)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap Edit to reorder or delete volume presets.")
                        Text("These quick buttons appear in the \(title.lowercased()) entry form.")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button("Save") {
                            saveVolumes()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadVolumes()
        }
        .alert("Add Volume", isPresented: $showingAddAlert) {
            TextField("Volume (\(unit))", text: $newVolumeText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addVolume()
            }
            .disabled(newVolumeText.trimmingCharacters(in: .whitespaces).isEmpty || Int(newVolumeText) == nil)
        } message: {
            Text("Enter a volume amount in \(unit)")
        }
    }
    
    // MARK: - Actions
    
    private func loadVolumes() {
        volumes = quickVolumesData.components(separatedBy: ",")
            .compactMap { component in
                Int(component.trimmingCharacters(in: .whitespaces))
            }
            .filter { $0 > 0 }
        
        // Ensure we have at least one volume
        if volumes.isEmpty {
            volumes = getDefaultVolumes()
        }
    }
    
    private func saveVolumes() {
        // Ensure we have at least one volume
        if volumes.isEmpty {
            volumes = getDefaultVolumes()
        }
        
        quickVolumesData = volumes.map(String.init).joined(separator: ",")
        dismiss()
    }
    
    private func addVolume() {
        guard let volume = Int(newVolumeText.trimmingCharacters(in: .whitespaces)),
              volume > 0,
              volume <= 1000,
              !volumes.contains(volume) else { return }
        
        volumes.append(volume)
        volumes.sort()
        newVolumeText = ""
    }
    
    private func deleteVolume(at offsets: IndexSet) {
        volumes.remove(atOffsets: offsets)
        
        // Ensure we always have at least one volume
        if volumes.isEmpty {
            volumes = getDefaultVolumes()
        }
    }
    
    private func moveVolume(from source: IndexSet, to destination: Int) {
        volumes.move(fromOffsets: source, toOffset: destination)
    }
    
    private func getDefaultVolumes() -> [Int] {
        if title.contains("Feed") {
            return [40, 60, 130, 150]
        } else {
            return [130, 140, 150, 170]
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sampleData = "40,60,130,150"
    
    return QuickVolumesEditorView(
        title: "Feed Quick Volumes",
        unit: "mL",
        quickVolumesData: $sampleData
    )
}