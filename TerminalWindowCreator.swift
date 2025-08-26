import SwiftUI
import Cocoa
import Foundation

@available(macOS 12.0, *)
@main
struct TerminalWindowCreatorApp: App {
    var body: some Scene {
        WindowGroup {
            TerminalCreatorView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct TerminalCreatorView: View {
    @State private var windowName = ""
    @State private var selectedFolder = ""
    @State private var showFolderPicker = false
    @State private var recentProjects: [ProjectMapping] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "terminal")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Create Terminal Window")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.top, 10)
            
            // Window Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Terminal Window Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter window name...", text: $windowName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Folder Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Map to Folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Select folder path...", text: $selectedFolder)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)
                    
                    Button("Browse") {
                        showFolderPicker = true
                    }
                    .controlSize(.regular)
                }
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Start")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    QuickProjectButton(title: "New Project", icon: "plus.circle", action: {
                        createNewProject()
                    })
                    
                    QuickProjectButton(title: "Home Directory", icon: "house", action: {
                        selectedFolder = FileManager.default.homeDirectoryForCurrentUser.path
                        windowName = "Home"
                    })
                    
                    QuickProjectButton(title: "Desktop", icon: "desktopcomputer", action: {
                        selectedFolder = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? ""
                        windowName = "Desktop"
                    })
                    
                    QuickProjectButton(title: "Documents", icon: "doc", action: {
                        selectedFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
                        windowName = "Documents"
                    })
                }
            }
            
            // Recent Projects
            if !recentProjects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(recentProjects.prefix(4), id: \.name) { project in
                            Button(action: {
                                windowName = project.name
                                selectedFolder = project.path
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.title3)
                                    Text(project.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    NSApplication.shared.keyWindow?.close()
                }
                .controlSize(.large)
                
                Button("Create Terminal") {
                    createTerminalWindow()
                }
                .controlSize(.large)
                .disabled(windowName.isEmpty || selectedFolder.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
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
            case .failure(let error):
                showAlert("Error selecting folder: \(error.localizedDescription)")
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Terminal Creator"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func createNewProject() {
        let dialog = NSOpenPanel()
        dialog.title = "Create New Project Folder"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canCreateDirectories = true
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            guard let result = dialog.url else { return }
            
            // Prompt for project name
            let alert = NSAlert()
            alert.messageText = "New Project Name"
            alert.informativeText = "Enter a name for the new project:"
            alert.alertStyle = .informational
            
            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            input.stringValue = "MyProject"
            alert.accessoryView = input
            
            alert.addButton(withTitle: "Create")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                let projectName = input.stringValue
                let projectPath = result.appendingPathComponent(projectName)
                
                do {
                    try FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true)
                    selectedFolder = projectPath.path
                    windowName = projectName
                } catch {
                    showAlert("Failed to create project folder: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createTerminalWindow() {
        guard !windowName.isEmpty && !selectedFolder.isEmpty else {
            showAlert("Please provide both window name and folder path")
            return
        }
        
        let terminal = TerminalManager()
        terminal.createWindowWithMapping(name: windowName, folderPath: selectedFolder) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveRecentProject()
                    showAlert("Terminal window '\(windowName)' created successfully!")
                    
                    // Close window after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        NSApplication.shared.keyWindow?.close()
                    }
                } else {
                    showAlert("Failed to create terminal: \(error ?? "Unknown error")")
                }
            }
        }
    }
    
    private func saveRecentProject() {
        let project = ProjectMapping(name: windowName, path: selectedFolder, lastUsed: Date())
        
        // Load existing and add new one
        var recent = loadProjectMappings()
        recent.removeAll { $0.name == windowName || $0.path == selectedFolder }
        recent.insert(project, at: 0)
        
        // Keep only last 10
        recent = Array(recent.prefix(10))
        
        saveProjectMappings(recent)
        recentProjects = recent
    }
    
    private func loadRecentProjects() {
        recentProjects = loadProjectMappings()
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct QuickProjectButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Terminal Management
class TerminalManager {
    func createWindowWithMapping(name: String, folderPath: String, completion: @escaping (Bool, String?) -> Void) {
        // Create AppleScript to open new terminal window with specific directory
        let script = """
        tell application "Terminal"
            activate
            
            -- Create new window and change directory
            do script "cd '\(folderPath)'"
            
            -- Get the ID of the new window
            set newWindowID to id of front window
            
            -- Set the window name
            set name of front window to "\(name)"
            
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
            
            // Save the mapping
            self.saveTerminalMapping(windowID: windowID, name: name, folderPath: folderPath)
            
            completion(true, nil)
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

// MARK: - Data Models
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

// MARK: - Persistence
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