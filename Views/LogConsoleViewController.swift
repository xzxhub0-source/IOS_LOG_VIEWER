import UIKit

class LogConsoleViewController: UIViewController {
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let logManager = LogManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupNavigationBar()
        
        // Add some test logs
        logManager.addLog("[XZX] Core initialized", source: "XZX")
        logManager.addLog("[XZX] Game detected - UI shown", level: .info, source: "XZX")
        logManager.addLog("[XZX] Lua script executed successfully", level: .debug, source: "XZX")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "XZX Log Console"
        
        searchBar.placeholder = "Search logs..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(LogCell.self, forCellReuseIdentifier: "LogCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearLogs))
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(showFilter))
        navigationItem.rightBarButtonItems = [clearButton, filterButton]
    }
    
    @objc private func clearLogs() {
        logManager.clearLogs()
        tableView.reloadData()
    }
    
    @objc private func showFilter() {
        let alert = UIAlertController(title: "Filter by Level", message: nil, preferredStyle: .actionSheet)
        
        let levels: [(LogEntry.LogLevel, String)] = [
            (.info, "INFO"), (.warning, "WARNING"), (.error, "ERROR"), (.debug, "DEBUG")
        ]
        
        for (level, name) in levels {
            let isSelected = logManager.selectedLevels.contains(level)
            alert.addAction(UIAlertAction(title: "\(isSelected ? "✓ " : "  ") \(name)", style: .default) { _ in
                if self.logManager.selectedLevels.contains(level) {
                    self.logManager.selectedLevels.remove(level)
                } else {
                    self.logManager.selectedLevels.insert(level)
                }
                self.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension LogConsoleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logManager.filteredLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath) as! LogCell
        let log = logManager.filteredLogs[indexPath.row]
        cell.configure(with: log)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let log = logManager.filteredLogs[indexPath.row]
        
        let alert = UIAlertController(title: "Log Details", message: """
            Level: \(log.level.rawValue)
            Time: \(DateFormatter.localizedString(from: log.timestamp, dateStyle: .medium, timeStyle: .medium))
            Source: \(log.source)
            
            Message:
            \(log.message)
            """, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LogConsoleViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logManager.searchText = searchText
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

class LogCell: UITableViewCell {
    private let levelIndicator = UIView()
    private let levelLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let sourceLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        levelIndicator.translatesAutoresizingMaskIntoConstraints = false
        levelIndicator.layer.cornerRadius = 4
        contentView.addSubview(levelIndicator)
        
        levelLabel.font = .systemFont(ofSize: 12, weight: .bold)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelLabel)
        
        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        
        timeLabel.font = .systemFont(ofSize: 10)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        sourceLabel.font = .systemFont(ofSize: 10)
        sourceLabel.textColor = .secondaryLabel
        sourceLabel.textAlignment = .right
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sourceLabel)
        
        NSLayoutConstraint.activate([
            levelIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            levelIndicator.centerYAnchor.constraint(equalTo: levelLabel.centerYAnchor),
            levelIndicator.widthAnchor.constraint(equalToConstant: 8),
            levelIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            levelLabel.leadingAnchor.constraint(equalTo: levelIndicator.trailingAnchor, constant: 8),
            levelLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            timeLabel.centerYAnchor.constraint(equalTo: levelLabel.centerYAnchor),
            
            sourceLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            sourceLabel.centerYAnchor.constraint(equalTo: levelLabel.centerYAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with log: LogEntry) {
        levelIndicator.backgroundColor = log.level.color
        levelLabel.text = log.level.rawValue
        levelLabel.textColor = log.level.color
        messageLabel.text = log.message
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        timeLabel.text = formatter.string(from: log.timestamp)
        sourceLabel.text = log.source
    }
}
