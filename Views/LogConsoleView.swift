import SwiftUI

struct LogConsoleView: View {
    @StateObject private var logManager = LogManager.shared
    @State private var showingSettings = false
    @State private var showingFilter = false
    @State private var exportURL: URL?
    @State private var showingExporter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with controls
                HStack {
                    Text("XZX Log Console")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingFilter.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                    
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $logManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Filter chips
                if showingFilter {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "INFO", level: .info, isSelected: logManager.selectedLevels.contains(.info)) {
                                toggleLevel(.info)
                            }
                            FilterChip(title: "WARNING", level: .warning, isSelected: logManager.selectedLevels.contains(.warning)) {
                                toggleLevel(.warning)
                            }
                            FilterChip(title: "ERROR", level: .error, isSelected: logManager.selectedLevels.contains(.error)) {
                                toggleLevel(.error)
                            }
                            FilterChip(title: "DEBUG", level: .debug, isSelected: logManager.selectedLevels.contains(.debug)) {
                                toggleLevel(.debug)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                
                // Log list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(logManager.filteredLogs) { log in
                            LogEntryView(entry: log)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { logManager.clearLogs() }) {
                            Label("Clear Logs", systemImage: "trash")
                        }
                        Button(action: exportLogs) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {
                            if logManager.isMonitoring {
                                logManager.stopMonitoring()
                            } else {
                                logManager.startMonitoring()
                            }
                        }) {
                            Label(
                                logManager.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                                systemImage: logManager.isMonitoring ? "pause.circle" : "play.circle"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
            .fileExporter(isPresented: $showingExporter, document: LogDocument(url: exportURL), contentType: .json, defaultFilename: "xzx_logs") { result in
                switch result {
                case .success:
                    print("Export successful")
                case .failure(let error):
                    print("Export failed: \(error)")
                }
            }
            .onAppear {
                logManager.startMonitoring()
            }
            .onDisappear {
                logManager.stopMonitoring()
            }
        }
    }
    
    private func toggleLevel(_ level: LogEntry.LogLevel) {
        if logManager.selectedLevels.contains(level) {
            logManager.selectedLevels.remove(level)
        } else {
            logManager.selectedLevels.insert(level)
        }
    }
    
    private func exportLogs() {
        exportURL = logManager.exportLogs()
        showingExporter = true
    }
}

struct FilterChip: View {
    let title: String
    let level: LogEntry.LogLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? level.color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Level indicator
            Circle()
                .fill(entry.level.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                // Header with timestamp and level
                HStack {
                    Text(entry.level.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(entry.level.color)
                    
                    Text(formatTime(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(entry.source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                // Message
                Text(entry.message)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct LogDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        url = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url, let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
