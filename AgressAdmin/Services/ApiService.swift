import Foundation

@MainActor
class ApiService: ObservableObject {
    @Published var products: [Product] = []
    @Published var logMessages: [String] = []
    private let settings: Settings

    init(settings: Settings) {
        self.settings = settings
    }

    var baseURL: String {
        settings.apiDomain
    }

    func fetchProducts() {
        guard let url = URL(string: "\(baseURL)/products") else { return }
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse else {
                    logMessages.append("Invalid response from server.")
                    return
                }

                let statusCode = httpResponse.statusCode

                if (200...299).contains(statusCode) {
                    let products = try JSONDecoder().decode([Product].self, from: data)
                    self.products = products
                    logMessages.append("Products fetched successfully. Status code: \(statusCode)")
                } else {
                    let message = "Error fetching products: Server returned status code \(statusCode)"
                    print(message)
                    logMessages.append(message)
                }
            } catch {
                let message = "Error fetching products: \(error.localizedDescription)"
                print(message)
                logMessages.append(message)
            }
        }
    }

    func deleteProduct(id: Int) {
        guard let url = URL(string: "\(baseURL)/product/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthHeader(to: &request)
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    logMessages.append("Invalid response from server.")
                    return
                }

                let statusCode = httpResponse.statusCode

                if (200...299).contains(statusCode) {
                    products.removeAll { $0.id == id }
                    logMessages.append("Product deleted successfully. Status code: \(statusCode)")
                } else {
                    let message = "Error deleting product: Server returned status code \(statusCode)"
                    print(message)
                    logMessages.append(message)
                }
            } catch {
                let message = "Error deleting product: \(error.localizedDescription)"
                print(message)
                logMessages.append(message)
            }
        }
    }

    func addProduct(_ product: Product, completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/product") else {
            completion(false, "Invalid URL.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(product)
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    let message = "Invalid response from server."
                    logMessages.append(message)
                    completion(false, message)
                    return
                }
                let statusCode = httpResponse.statusCode
                if (200...299).contains(statusCode) {
                    logMessages.append("Product added successfully. Status code: \(statusCode)")
                    completion(true, nil)
                } else {
                    let message = "Error adding product: Server returned status code \(statusCode)"
                    print(message)
                    logMessages.append(message)
                    completion(false, message)
                }
            } catch {
                let message = "Error adding product: \(error.localizedDescription)"
                print(message)
                logMessages.append(message)
                completion(false, message)
            }
        }
    }

    func updateProduct(_ product: Product, completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        guard let id = product.id, let url = URL(string: "\(baseURL)/product/\(id)") else {
            completion(false, "Invalid product ID or URL.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        addAuthHeader(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(product)
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    let message = "Invalid response from server."
                    logMessages.append(message)
                    completion(false, message)
                    return
                }
                let statusCode = httpResponse.statusCode
                if (200...299).contains(statusCode) {
                    logMessages.append("Product updated successfully. Status code: \(statusCode)")
                    completion(true, nil)
                } else {
                    let message = "Error updating product: Server returned status code \(statusCode)"
                    print(message)
                    logMessages.append(message)
                    completion(false, message)
                }
            } catch {
                let message = "Error updating product: \(error.localizedDescription)"
                print(message)
                logMessages.append(message)
                completion(false, message)
            }
        }
    }

    private func addAuthHeader(to request: inout URLRequest) {
        if !settings.adminApiKey.isEmpty {
            request.setValue("Bearer \(settings.adminApiKey)", forHTTPHeaderField: "Authorization")
        }
    }
}

