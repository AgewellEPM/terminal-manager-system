import SwiftUI
import Cocoa
import Foundation

@available(macOS 12.0, *)
@main
struct TerminalCreatorMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    private var popover: NSPopover!
    private var terminalManager: TerminalManager!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Terminal Creator")
            statusBarButton.action = #selector(statusBarButtonClicked)
            statusBarButton.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: TerminalCreatorPopoverView())
        popover.behavior = .transient
        
        // Initialize terminal manager
        terminalManager = TerminalManager()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func statusBarButtonClicked() {
        if let statusBarButton = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
            }
        }
    }
}

struct TerminalCreatorPopoverView: View {
    @State private var windowName = ""
    @State private var selectedFolder = ""
    @State private var showFolderPicker = false
    @State private var recentProjects: [ProjectMapping] = []
    @State private var isCreating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.blue)
                Text("Quick Terminal")
                    .font(.headline)
                Spacer()
            }
            
            // Quick Actions
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                QuickActionButton(title: "Home", icon: "house") {
                    createQuickTerminal(name: "Home", path: FileManager.default.homeDirectoryForCurrentUser.path)
                }
                
                QuickActionButton(title: "Desktop", icon: "desktopcomputer") {
                    let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? ""
                    createQuickTerminal(name: "Desktop", path: desktopPath)
                }
                
                QuickActionButton(title: "Documents", icon: "doc") {
                    let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
                    createQuickTerminal(name: "Documents", path: docsPath)
                }
                
                QuickActionButton(title: "Downloads", icon: "arrow.down.circle") {
                    let downloadsPath = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first ?? ""
                    createQuickTerminal(name: "Downloads", path: downloadsPath)
                }
            }
            
            Divider()
            
            // Custom Terminal Section
            VStack(spacing: 8) {
                Text("Custom Terminal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Terminal name", text: $windowName)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    TextField("Folder path", text: $selectedFolder)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)
                    
                    Button("Browse") {
                        showFolderPicker = true
                    }
                    .controlSize(.small)
                }
                
                Button(isCreating ? "Creating..." : "Create Terminal") {
                    createCustomTerminal()
                }
                .controlSize(.large)
                .disabled(windowName.isEmpty || selectedFolder.isEmpty || isCreating)
            }
            
            // Recent Projects
            if !recentProjects.isEmpty {
                Divider()
                
                VStack(spacing: 8) {
                    Text("Recent Projects")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVStack(spacing: 4) {
                        ForEach(recentProjects.prefix(3), id: \.name) { project in
                            Button(action: {
                                createQuickTerminal(name: project.name, path: project.path)
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.blue)
                                    Text(project.name)
                                        .font(.caption)
                                    Spacer()
                                    Text(formatDate(project.lastUsed))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Open Full Creator") {
                    openFullCreator()
                }
                .font(.caption)
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            loadRecentProjects()
        }
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url):
                selectedFolder = url.path
                if windowName.isEmpty {
                    windowName = url.lastPathComponent
                }
            case .failure:
                break
            }
        }
    }
    
    private func createQuickTerminal(name: String, path: String) {
        let terminal = TerminalManager()
        terminal.createWindowWithMapping(name: name, folderPath: path) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveRecentProject(name: name, path: path)
                    closePopover()
                }
            }
        }
    }
    
    private func createCustomTerminal() {
        guard !windowName.isEmpty && !selectedFolder.isEmpty else { return }
        
        isCreating = true
        let terminal = TerminalManager()
        terminal.createWindowWithMapping(name: windowName, folderPath: selectedFolder) { success, error in
            DispatchQueue.main.async {
                isCreating = false
                if success {
                    saveRecentProject(name: windowName, path: selectedFolder)
                    closePopover()
                }
            }
        }
    }
    
    private func saveRecentProject(name: String, path: String) {
        let project = ProjectMapping(name: name, path: path, lastUsed: Date())
        var recent = loadProjectMappings()
        recent.removeAll { $0.name == name || $0.path == path }
        recent.insert(project, at: 0)
        recent = Array(recent.prefix(10))
        saveProjectMappings(recent)
        recentProjects = recent
    }
    
    private func loadRecentProjects() {
        recentProjects = loadProjectMappings()
    }
    
    private func closePopover() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.statusBarItem.button?.performClick(nil)
        }
    }
    
    private func openFullCreator() {
        // Launch the full terminal creator app
        let task = Process()
        task.launchPath = "/usr/bin/swift"
        task.arguments = ["\(FileManager.default.homeDirectoryForCurrentUser.path)/TerminalWindowCreator.swift"]
        try? task.run()
        closePopover()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Terminal Management
class TerminalManager {
    func createWindowWithMapping(name: String, folderPath: String, completion: @escaping (Bool, String?) -> Void) {
        let script = """
        tell application "Terminal"
            activate
            
            -- Create new window and change directory
            do script "cd '\(folderPath)'"
            
            -- Get the ID of the new window
            set newWindowID to id of front window
            
            -- Set the window name with project indicator
            set custom title of front window to "[\(name)] \(URL(fileURLWithPath: folderPath).lastPathComponent)"
            
            -- Return window ID for mapping
            return newWindowID as string
        end tell
        """
        
        executeAppleScript(script) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let windowID = result?.trimmingCharacters(in: .whitespacesAndNewlines), !windowID.isEmpty else {
                completion(false, "Failed to get window ID")
                return
            }
            
            // Save the mapping to TinkyBink system
            self.saveToTinkyBinkMapping(windowID: windowID, name: name)
            
            // Also save to our own system
            self.saveTerminalMapping(windowID: windowID, name: name, folderPath: folderPath)
            
            completion(true, nil)
        }
    }
    
    private func saveToTinkyBinkMapping(windowID: String, name: String) {
        // Save to existing TinkyBink mapping file
        let mappingFile = URL(fileURLWithPath: NSString(string: "~/.tinkybink_terminal_mappings.json").expandingTildeInPath)
        
        do {
            var mappings: [String: String] = [:]
            
            // Load existing mappings
            if let data = try? Data(contentsOf: mappingFile),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                mappings = existing
            }
            
            // Add new mapping
            mappings[windowID] = name
            
            // Save updated mappings
            let data = try JSONSerialization.data(withJSONObject: mappings, options: .prettyPrinted)
            try data.write(to: mappingFile)
        } catch {
            print("Failed to save TinkyBink mapping: \(error)")
        }
    }
    
    private func saveTerminalMapping(windowID: String, name: String, folderPath: String) {
        let mapping = TerminalMapping(
            windowID: windowID,
            name: name,
            folderPath: folderPath,
            created: Date(),
            lastUsed: Date()
        )
        
        var mappings = loadTerminalMappings()
        mappings[windowID] = mapping
        saveTerminalMappings(mappings)
    }
    
    private func executeAppleScript(_ script: String, completion: @escaping (String?, Error?) -> Void) {
        DispatchQueue.global().async {
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        completion(output, nil)
                    } else {
                        completion(nil, NSError(domain: "TerminalManager", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output]))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
}

// MARK: - Data Models (reused from main app)
struct ProjectMapping: Codable, Identifiable {
    var id: String { name }
    let name: String
    let path: String
    let lastUsed: Date
}

struct TerminalMapping: Codable {
    let windowID: String
    let name: String
    let folderPath: String
    let created: Date
    let lastUsed: Date
}

// MARK: - Persistence (reused from main app)
private let projectMappingsURL: URL = {
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return url.appendingPathComponent("TerminalCreator").appendingPathComponent("projects.json")
}()

private let terminalMappingsURL: URL = {
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return url.appendingPathComponent("TerminalCreator").appendingPathComponent("terminals.json")
}()

func loadProjectMappings() -> [ProjectMapping] {
    guard let data = try? Data(contentsOf: projectMappingsURL),
          let mappings = try? JSONDecoder().decode([ProjectMapping].self, from: data) else {
        return []
    }
    return mappings.sorted { $0.lastUsed > $1.lastUsed }
}

func saveProjectMappings(_ mappings: [ProjectMapping]) {
    do {
        try FileManager.default.createDirectory(at: projectMappingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(mappings)
        try data.write(to: projectMappingsURL)
    } catch {
        print("Failed to save project mappings: \(error)")
    }
}

func loadTerminalMappings() -> [String: TerminalMapping] {
    guard let data = try? Data(contentsOf: terminalMappingsURL),
          let mappings = try? JSONDecoder().decode([String: TerminalMapping].self, from: data) else {
        return [:]
    }
    return mappings
}

func saveTerminalMappings(_ mappings: [String: TerminalMapping]) {
    do {
        try FileManager.default.createDirectory(at: terminalMappingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(mappings)
        try data.write(to: terminalMappingsURL)
    } catch {
        print("Failed to save terminal mappings: \(error)")
    }
}