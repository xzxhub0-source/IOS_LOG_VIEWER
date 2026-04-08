import Foundation
import UIKit

struct LogEntry: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel
    let source: String
    
    enum LogLevel: String, Codable {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case debug = "DEBUG"
        
        var color: UIColor {
            switch self {
            case .info: return .systemBlue
            case .warning: return .systemOrange
            case .error: return .systemRed
            case .debug: return .systemGreen
            }
        }
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var isMonitoring = false
    @Published var searchText = ""
    @Published var selectedLevels: Set<LogEntry.LogLevel> = [.info, .warning, .error, .debug]
    
    private var timer: Timer?
    private let logFileURL: URL
    private let maxLogEntries = 1000
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = documentsPath.appendingPathComponent("xzx_logs.json")
        loadLogs()
    }
    
    func startMonitoring() {
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.readSystemLogs()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    private func readSystemLogs() {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = ["show", "--predicate", "process == 'Roblox'", "--last", "2s"]
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseLogOutput(output)
            }
        } catch {
            print("Failed to read logs: \(error)")
        }
    }
    
    private func parseLogOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("[XZX]") {
                addLogEntry(from: line, source: "Roblox")
            } else if line.contains("XZX") {
                addLogEntry(from: line, source: "Executor")
            }
        }
    }
    
    private func addLogEntry(from line: String, source: String) {
        var level: LogEntry.LogLevel = .info
        var message = line
        
        if line.contains("ERROR") || line.contains("Error") {
            level = .error
        } else if line.contains("WARN") || line.contains("Warning") {
            level = .warning
        } else if line.contains("DEBUG") {
            level = .debug
        }
        
        if let range = line.range(of: "\\[XZX\\]|XZX", options: .regularExpression) {
            message = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        
        let entry = LogEntry(timestamp: Date(), message: message, level: level, source: source)
        
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            if self.logs.count > self.maxLogEntries {
                self.logs.removeLast()
            }
            self.saveLogs()
        }
    }
    
    func addManualLog(_ message: String, level: LogEntry.LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), message: message, level: level, source: "Manual")
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            if self.logs.count > self.maxLogEntries {
                self.logs.removeLast()
            }
            self.saveLogs()
        }
    }
    
    func clearLogs() {
        logs.removeAll()
        saveLogs()
    }
    
    func exportLogs() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(logs)
            let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("xzx_logs_\(Date().timeIntervalSince1970).json")
            try data.write(to: exportURL)
            return exportURL
        } catch {
            print("Failed to export logs: \(error)")
            return nil
        }
    }
    
    private func saveLogs() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(logs)
            try data.write(to: logFileURL)
        } catch {
            print("Failed to save logs: \(error)")
        }
    }
    
    private func loadLogs() {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: logFileURL)
            logs = try decoder.decode([LogEntry].self, from: data)
        } catch {
            print("Failed to load logs: \(error)")
        }
    }
    
    var filteredLogs: [LogEntry] {
        logs.filter { log in
            let matchesLevel = selectedLevels.contains(log.level)
            let matchesSearch = searchText.isEmpty || log.message.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }
}
