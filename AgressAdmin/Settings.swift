import Foundation

class Settings: ObservableObject {
    @Published var apiDomain: String {
        didSet {
            UserDefaults.standard.set(apiDomain, forKey: "apiDomain")
        }
    }
    
    @Published var adminApiKey: String {
        didSet {
            UserDefaults.standard.set(adminApiKey, forKey: "adminApiKey")
        }
    }
    
    init() {
        // Load saved settings or use defaults
        self.apiDomain = UserDefaults.standard.string(forKey: "apiDomain") ?? "https://api.swabcity.shop"
        self.adminApiKey = UserDefaults.standard.string(forKey: "adminApiKey") ?? ""
    }
}
