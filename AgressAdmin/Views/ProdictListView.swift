import SwiftUI

struct ProductListView: View {
    @StateObject private var settings = Settings()
    @StateObject private var apiService: ApiService

    @State private var showAddView = false
    @State private var showSettingsView = false

    init() {
        let settings = Settings()
        _settings = StateObject(wrappedValue: settings)
        _apiService = StateObject(wrappedValue: ApiService(settings: settings))
    }

    var body: some View {
        NavigationStack {
            VStack {
                List(apiService.products) { product in
                    ProductRowView(product: product, apiService: apiService)
                }
                .navigationTitle("Products")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddView = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $showAddView) {
                            EditProductView(
                                apiService: apiService,
                                product: Product(
                                    id: nil,
                                    name: "",
                                    price: 0.0,
                                    currency: "XMR",
                                    description: "",
                                    image: ""
                                ),
                                isEditing: false
                            )
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showSettingsView = true
                        }) {
                            Image(systemName: "gear")
                        }
                        .sheet(isPresented: $showSettingsView) {
                            SettingsView(settings: settings)
                        }
                    }
                }
                .onAppear {
                    apiService.fetchProducts()
                }

                Spacer()

                // Log messages view
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(apiService.logMessages, id: \.self) { message in
                            Text(message)
                                .font(.caption)
                                .padding(.vertical, 2)
                                .foregroundColor(message.contains("Error") ? .red : .primary)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 150) // Adjust height as needed
                .background(Color.black)
            }
        }
    }
}

