import Foundation
import UIKit

public class LogCapture: NSObject {
    public static let shared = LogCapture()
    
    private var logFileURL: URL?
    private var logEntries: [LogEntry] = []
    private let dateFormatter: DateFormatter
    private let fileHandle: FileHandle?
    
    public struct LogEntry: Codable {
        public let timestamp: Date
        public let message: String
        public let level: LogLevel
        public let file: String
        public let line: Int
        public let function: String
        
        public var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }
    }
    
    public enum LogLevel: String, Codable, CaseIterable {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case critical = "💀 CRITICAL"
        
        var color: UIColor {
            switch self {
            case .debug: return .systemGray
            case .info: return .systemBlue
            case .warning: return .systemOrange
            case .error: return .systemRed
            case .critical: return .systemPurple
            }
        }
    }
    
    private override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logFileURL = documentsPath.appendingPathComponent("xzx_logs.json")
        
        if let url = logFileURL, FileManager.default.fileExists(atPath: url.path) {
            fileHandle = try? FileHandle(forWritingTo: url)
            fileHandle?.seekToEndOfFile()
            loadExistingLogs()
        } else {
            fileHandle = nil
        }
        
        super.init()
        
        // Redirect NSLog and stdout/stderr
        setupLogRedirect()
    }
    
    private func setupLogRedirect() {
        // Create a pipe for stdout
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        setvbuf(stdout, nil, _IONBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
        
        dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(stderrPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.captureOutput(output, level: .info)
            }
        }
        
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.captureOutput(output, level: .error)
            }
        }
    }
    
    private func loadExistingLogs() {
        guard let url = logFileURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        logEntries = entries
    }
    
    private func captureOutput(_ output: String, level: LogLevel) {
        let entry = LogEntry(
            timestamp: Date(),
            message: output.trimmingCharacters(in: .whitespacesAndNewlines),
            level: level,
            file: "system",
            line: 0,
            function: ""
        )
        addEntry(entry)
    }
    
    public func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line, function: String = #function) {
        let entry = LogEntry(
            timestamp: Date(),
            message: message,
            level: level,
            file: (file as NSString).lastPathComponent,
            line: line,
            function: function
        )
        addEntry(entry)
    }
    
    private func addEntry(_ entry: LogEntry) {
        logEntries.append(entry)
        
        // Keep only last 5000 entries
        if logEntries.count > 5000 {
            logEntries.removeFirst(logEntries.count - 5000)
        }
        
        // Write to file
        if let url = logFileURL,
           let data = try? JSONEncoder().encode(logEntries) {
            try? data.write(to: url)
        }
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .newLogEntry, object: entry)
        }
        
        // Also print to console for debugging
        print("[\(entry.level.rawValue)] \(entry.formattedTimestamp): \(entry.message)")
    }
    
    public func getLogs() -> [LogEntry] {
        return logEntries
    }
    
    public func clearLogs() {
        logEntries.removeAll()
        if let url = logFileURL {
            try? "[]".write(to: url, atomically: true, encoding: .utf8)
        }
        NotificationCenter.default.post(name: .logsCleared, object: nil)
    }
    
    public func exportLogs() -> URL? {
        let exportFormatter = DateFormatter()
        exportFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "xzx_logs_\(exportFormatter.string(from: Date())).txt"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        var exportText = "XZX Executor Log Export\n"
        exportText += "========================\n"
        exportText += "Export Date: \(Date())\n"
        exportText += "Total Entries: \(logEntries.count)\n\n"
        
        for entry in logEntries {
            exportText += "[\(entry.level.rawValue)] \(entry.formattedTimestamp)\n"
            exportText += "\(entry.message)\n"
            if !entry.file.isEmpty {
                exportText += "  ↳ \(entry.file):\(entry.line) - \(entry.function)\n"
            }
            exportText += "\n"
        }
        
        try? exportText.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}

extension Notification.Name {
    static let newLogEntry = Notification.Name("newLogEntry")
    static let logsCleared = Notification.Name("logsCleared")
}
