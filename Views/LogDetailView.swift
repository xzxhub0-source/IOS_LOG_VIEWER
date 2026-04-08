import SwiftUI

struct LogDetailView: View {
    let entry: LogEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.level.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(entry.level.color)
                            
                            Spacer()
                            
                            Text(formatDateTime(entry.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        Text(entry.message)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.headline)
                        
                        HStack {
                            Text("Source:")
                                .foregroundColor(.secondary)
                            Text(entry.source)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("ID:")
                                .foregroundColor(.secondary)
                            Text(entry.id.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Log Details")
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
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
