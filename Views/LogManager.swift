import Foundation
import UIKit

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let level: LogLevel
    let source: String
    
    enum LogLevel: String {
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
    @Published var searchText = ""
    @Published var selectedLevels: Set<LogEntry.LogLevel> = [.info, .warning, .error, .debug]
    
    private init() {}
    
    func addLog(_ message: String, level: LogEntry.LogLevel = .info, source: String = "Executor") {
        let entry = LogEntry(timestamp: Date(), message: message, level: level, source: source)
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            if self.logs.count > 1000 {
                self.logs.removeLast()
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    var filteredLogs: [LogEntry] {
        logs.filter { log in
            let matchesLevel = selectedLevels.contains(log.level)
            let matchesSearch = searchText.isEmpty || log.message.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }
}
