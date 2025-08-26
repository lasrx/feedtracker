import SwiftUI

// MARK: - Generic Swipe Actions Component

struct SwipeActionsView<RowContent: View, Item>: View where Item: Identifiable {
    let items: [Item]
    let rowContent: (Item) -> RowContent
    let onEdit: (Item) -> Void
    let onDelete: (Item) -> Void
    let editColor: Color
    let editLabel: String
    let deleteLabel: String
    
    var body: some View {
        List(items) { item in
            rowContent(item)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        onEdit(item)
                    } label: {
                        Label(editLabel, systemImage: "pencil")
                    }
                    .tint(editColor)
                    
                    Button {
                        onDelete(item)
                    } label: {
                        Label(deleteLabel, systemImage: "trash")
                    }
                    .tint(.red)
                }
                .contextMenu {
                    Button {
                        onEdit(item)
                    } label: {
                        Label("Edit \(editLabel)", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete(item)
                    } label: {
                        Label("Delete \(deleteLabel)", systemImage: "trash")
                    }
                }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Generic Delete Alert Component

struct DeleteAlertModifier<Item>: ViewModifier where Item: Identifiable {
    @Binding var showAlert: Bool
    @Binding var itemToDelete: Item?
    let itemType: String
    let itemDescription: (Item) -> String
    let onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Delete \(itemType)", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onConfirm()
                }
            } message: {
                if let item = itemToDelete {
                    Text("Are you sure you want to delete \(itemDescription(item))?")
                }
            }
    }
}

extension View {
    func deleteAlert<Item: Identifiable>(
        isPresented: Binding<Bool>,
        item: Binding<Item?>,
        itemType: String,
        itemDescription: @escaping (Item) -> String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(DeleteAlertModifier(
            showAlert: isPresented,
            itemToDelete: item,
            itemType: itemType,
            itemDescription: itemDescription,
            onConfirm: onConfirm
        ))
    }
}