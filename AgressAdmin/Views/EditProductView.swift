// EditProductView.swift
import SwiftUI

struct EditProductView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var apiService: ApiService
    @State var product: Product

    var isEditing: Bool

    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImageData: Data?
    @State private var imageMimeType: String?

    // Configured NumberFormatter
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2 // Adjust as needed
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        Form {
            TextField("Product Name", text: $product.name)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.default)
                .textContentType(.none)
                .textInputAutocapitalization(.never)

            TextField("Price", value: $product.price, formatter: Self.decimalFormatter)
                .keyboardType(.decimalPad)
                .disableAutocorrection(true)
                

            TextField("Currency", text: $product.currency)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                

            TextField("Description", text: $product.description)
                .autocapitalization(.sentences)
                .disableAutocorrection(true)
                .keyboardType(.default)
                .textContentType(.none)
                

            // Display Selected Image
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }

            Button(action: {
                showImagePicker = true
            }) {
                Text("Select Image")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(imageData: $selectedImageData, mimeType: $imageMimeType)
                    .onDisappear {
                        if let data = selectedImageData, let mimeType = imageMimeType {
                            // Encode image as base64 and prepend the required prefix
                            let base64String = data.base64EncodedString()
                            self.product.image = "data:\(mimeType);base64,\(base64String)"
                        }
                    }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button(action: saveProduct) {
                Text(isEditing ? "Save Changes" : "Add Product")
            }
        }
        .navigationTitle(isEditing ? "Edit Product" : "Add Product")
        .onAppear {
            // If editing, load the existing image data
            if isEditing,
               let dataRange = product.image.range(of: ";base64,") {
                // Extract the MIME type and base64 data
                let mimeTypeRange = product.image.range(of: "data:")!.upperBound..<dataRange.lowerBound
                let mimeType = String(product.image[mimeTypeRange])
                let base64Data = String(product.image[dataRange.upperBound...])
                if let data = Data(base64Encoded: base64Data) {
                    selectedImageData = data
                    imageMimeType = mimeType
                }
            }
        }
    }

    func saveProduct() {
        if isEditing {
            apiService.updateProduct(product) { success, error in
                if success {
                    presentationMode.wrappedValue.dismiss()
                } else if let error = error {
                    errorMessage = error
                }
            }
        } else {
            apiService.addProduct(product) { success, error in
                if success {
                    apiService.fetchProducts()
                    presentationMode.wrappedValue.dismiss()
                } else if let error = error {
                    errorMessage = error
                }
            }
        }
    }
}

// ImagePicker.swift
import SwiftUI
import MobileCoreServices

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var mimeType: String?

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true // Enable editing and cropping
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)

            if let selectedImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
                // Process the image to meet the 2MB limit
                if let processedData = processImage(selectedImage) {
                    DispatchQueue.main.async {
                        self.parent.imageData = processedData
                        self.parent.mimeType = "image/jpeg" // Changed to JPEG for compatibility
                    }
                } else {
                    print("Failed to process image to meet size constraints.")
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // Helper Function to Process Image
        private func processImage(_ image: UIImage) -> Data? {
            var compressionQuality: CGFloat = 0.9 // Start with high quality
            var resizedImage = image
            var imageData: Data?

            while compressionQuality > 0.1 {
                if let data = resizedImage.jpegData(compressionQuality: compressionQuality) {
                    if data.count <= 2 * 1000 * 1000 { // 2MB limit
                        return data
                    } else {
                        // Reduce compression quality
                        compressionQuality -= 0.1
                    }
                }

                // Downscale the image if needed
                resizedImage = downscaleImage(resizedImage, maxDimension: resizedImage.size.width * 0.8)
            }

            return imageData
        }

        // Helper Function to Downscale UIImage
        private func downscaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
            let aspectRatio = image.size.width / image.size.height
            let newSize: CGSize

            if image.size.width > image.size.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }

            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
}
