import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Domain")) {
                    TextField("Enter API Domain", text: $settings.apiDomain)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section(header: Text("Admin API Key")) {
                    SecureField("Enter Admin API Key", text: $settings.adminApiKey)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
