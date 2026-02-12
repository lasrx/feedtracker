import SwiftUI

struct FormulaTypesEditorView: View {
    @Binding var formulaTypesData: String
    @State private var formulaTypes: [String] = []
    @State private var showingAddAlert = false
    @State private var newFormulaType = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(formulaTypes.indices, id: \.self) { index in
                        HStack {
                            Text(formulaTypes[index])
                                .font(.body)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .onDelete(perform: deleteFormulaType)
                    .onMove(perform: moveFormulaType)
                    
                    // Add New Button
                    Button(action: {
                        newFormulaType = ""
                        showingAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text("Add Formula Type")
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Formula Types")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap Edit to reorder or delete formula types.")
                        Text("The first formula type will be the default selection.")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Formula Types")
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button("Save") {
                            saveFormulaTypes()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadFormulaTypes()
        }
        .alert("Add Formula Type", isPresented: $showingAddAlert) {
            TextField("Formula name", text: $newFormulaType)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addFormulaType()
            }
            .disabled(newFormulaType.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Enter the name of the new formula type")
        }
    }
    
    // MARK: - Actions
    
    private func loadFormulaTypes() {
        if formulaTypesData.isEmpty {
            formulaTypes = FeedConstants.defaultFormulaTypes
        } else {
            formulaTypes = formulaTypesData.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }
    
    private func saveFormulaTypes() {
        // Ensure we have at least one formula type
        if formulaTypes.isEmpty {
            formulaTypes = FeedConstants.defaultFormulaTypes
        }
        
        formulaTypesData = formulaTypes.joined(separator: ",")
        dismiss()
    }
    
    private func addFormulaType() {
        let trimmed = newFormulaType.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !formulaTypes.contains(trimmed) {
            formulaTypes.append(trimmed)
        }
        newFormulaType = ""
    }
    
    private func deleteFormulaType(at offsets: IndexSet) {
        formulaTypes.remove(atOffsets: offsets)
        
        // Ensure we always have at least one formula type
        if formulaTypes.isEmpty {
            formulaTypes = [FeedConstants.defaultFormulaTypes.first ?? "Breast milk"]
        }
    }
    
    private func moveFormulaType(from source: IndexSet, to destination: Int) {
        formulaTypes.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sampleData = "Breast milk,Similac 360,Enfamil Neuropro"
    
    return FormulaTypesEditorView(formulaTypesData: $sampleData)
}