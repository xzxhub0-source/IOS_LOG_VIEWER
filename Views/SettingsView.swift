import SwiftUI

struct SettingsView: View {
    @AppStorage("autoScroll") private var autoScroll = true
    @AppStorage("maxLogEntries") private var maxLogEntries = 1000
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("darkMode") private var darkMode = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display")) {
                    Toggle("Auto-scroll to new logs", isOn: $autoScroll)
                    Toggle("Dark Mode", isOn: $darkMode)
                        .onChange(of: darkMode) { newValue in
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.forEach { window in
                                    window.overrideUserInterfaceStyle = newValue ? .dark : .light
                                }
                            }
                        }
                    
                    Picker("Max Log Entries", selection: $maxLogEntries) {
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                        Text("2000").tag(2000)
                        Text("5000").tag(5000)
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                    if notificationEnabled {
                        Button("Request Permission") {
                            NotificationManager.shared.requestAuthorization()
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
