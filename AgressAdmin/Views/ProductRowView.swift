import SwiftUI

struct ProductRowView: View {
    let product: Product
    @ObservedObject var apiService: ApiService
    @State private var showEditView = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            if let imageData = product.decodedImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            } else {
                Color.gray
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                Text("\(product.price, specifier: "%.2f") \(product.currency)")
                    .font(.subheadline)
                Text(product.description)
                    .font(.caption)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        // Swipe action for delete (swipe from right to left)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        // Swipe action for edit (swipe from left to right)
        .swipeActions(edge: .leading) {
            Button {
                showEditView = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        // Confirmation alert before deleting
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Product"),
                message: Text("Are you sure you want to delete this product?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let id = product.id {
                        apiService.deleteProduct(id: id)
                    } else {
                        print("Error: Product ID is nil")
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // Edit product sheet
        .sheet(isPresented: $showEditView) {
            EditProductView(apiService: apiService, product: product, isEditing: true)
        }
    }
}
