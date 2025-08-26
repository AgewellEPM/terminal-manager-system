import SwiftUI
import Cocoa
import Foundation

@available(macOS 12.0, *)
@main
struct TerminalManagerMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    private var menu: NSMenu!
    private var terminalManager: TerminalManager!
    private var hoodrobotIntegration: HoodrobotIntegration!
    private var updateTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = createTerminalIcon()
            statusBarButton.toolTip = "Terminal Manager"
        }
        
        // Initialize managers
        terminalManager = TerminalManager()
        hoodrobotIntegration = HoodrobotIntegration()
        
        // Create menu
        setupMenu()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateMenu()
        }
    }
    
    func setupMenu() {
        menu = NSMenu()
        
        // Header
        let headerItem = NSMenuItem(title: "Terminal Manager", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Quick Actions Section
        let quickActionsItem = NSMenuItem(title: "Quick Actions", action: nil, keyEquivalent: "")
        quickActionsItem.submenu = createQuickActionsMenu()
        menu.addItem(quickActionsItem)
        
        // Terminal Windows Section
        let terminalsItem = NSMenuItem(title: "Terminal Windows", action: nil, keyEquivalent: "")
        terminalsItem.submenu = createTerminalsMenu()
        menu.addItem(terminalsItem)
        
        // Rename Section
        let renameItem = NSMenuItem(title: "Rename Terminals", action: nil, keyEquivalent: "")
        renameItem.submenu = createRenameMenu()
        menu.addItem(renameItem)
        
        // Hoodrobot Integration
        if hoodrobotIntegration.isHoodrobotRunning() {
            menu.addItem(NSMenuItem.separator())
            let hoodrobotItem = NSMenuItem(title: "🤖 Hoodrobot", action: nil, keyEquivalent: "")
            hoodrobotItem.submenu = createHoodrobotMenu()
            menu.addItem(hoodrobotItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        
        // GitHub
        menu.addItem(NSMenuItem(title: "View on GitHub", action: #selector(openGitHub), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit Terminal Manager", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
    }
    
    func createQuickActionsMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "New Terminal Window", action: #selector(createNewTerminal), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "New Terminal at Desktop", action: #selector(createDesktopTerminal), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "New Terminal at Home", action: #selector(createHomeTerminal), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "New Terminal at Documents", action: #selector(createDocumentsTerminal), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "New Project Terminal...", action: #selector(createProjectTerminal), keyEquivalent: "p"))
        
        return menu
    }
    
    func createTerminalsMenu() -> NSMenu {
        let menu = NSMenu()
        
        let terminals = terminalManager.getAllTerminals()
        
        if terminals.isEmpty {
            let emptyItem = NSMenuItem(title: "No terminals open", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for terminal in terminals {
                let item = NSMenuItem(title: "\(terminal.name) [\(terminal.id)]", action: #selector(focusTerminal(_:)), keyEquivalent: "")
                item.representedObject = terminal.id
                
                // Add submenu for actions
                let submenu = NSMenu()
                
                let renameItem = NSMenuItem(title: "Rename...", action: #selector(renameTerminal(_:)), keyEquivalent: "")
                renameItem.representedObject = terminal.id
                submenu.addItem(renameItem)
                
                let closeItem = NSMenuItem(title: "Close", action: #selector(closeTerminal(_:)), keyEquivalent: "")
                closeItem.representedObject = terminal.id
                submenu.addItem(closeItem)
                
                item.submenu = submenu
                menu.addItem(item)
            }
        }
        
        return menu
    }
    
    func createRenameMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Rename Current Terminal", action: #selector(renameCurrentTerminal), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Rename All Terminals...", action: #selector(renameAllTerminals), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Apply Naming Scheme", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "  → Project-based", action: #selector(applyProjectNaming), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "  → Function-based", action: #selector(applyFunctionNaming), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "  → Workspace-based", action: #selector(applyWorkspaceNaming), keyEquivalent: ""))
        
        return menu
    }
    
    func createHoodrobotMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Screenshot to Terminal", action: #selector(screenshotToTerminal), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Send File to Terminal", action: #selector(sendFileToTerminal), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Capture Terminal Output", action: #selector(captureTerminalOutput), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Toggle Focus Indicators", action: #selector(toggleFocusIndicators), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Terminal Statistics", action: #selector(showStatistics), keyEquivalent: ""))
        
        return menu
    }
    
    func updateMenu() {
        // Update terminal list
        if let terminalsItem = menu.item(withTitle: "Terminal Windows") {
            terminalsItem.submenu = createTerminalsMenu()
        }
        
        // Update Hoodrobot status
        let hasHoodrobot = menu.item(withTitle: "🤖 Hoodrobot") != nil
        let isRunning = hoodrobotIntegration.isHoodrobotRunning()
        
        if isRunning && !hasHoodrobot {
            // Add Hoodrobot menu
            let separatorIndex = menu.items.count - 4
            menu.insertItem(NSMenuItem.separator(), at: separatorIndex)
            let hoodrobotItem = NSMenuItem(title: "🤖 Hoodrobot", action: nil, keyEquivalent: "")
            hoodrobotItem.submenu = createHoodrobotMenu()
            menu.insertItem(hoodrobotItem, at: separatorIndex + 1)
        } else if !isRunning && hasHoodrobot {
            // Remove Hoodrobot menu
            let index = menu.indexOfItem(withTitle: "🤖 Hoodrobot")
            if index >= 0 {
                menu.removeItem(at: index)
                if index > 0 && menu.item(at: index - 1)?.isSeparatorItem == true {
                    menu.removeItem(at: index - 1)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func createNewTerminal() {
        terminalManager.createNewTerminal()
    }
    
    @objc func createDesktopTerminal() {
        let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? ""
        terminalManager.createWindowWithMapping(name: "Desktop", folderPath: desktopPath) { _, _ in }
    }
    
    @objc func createHomeTerminal() {
        terminalManager.createWindowWithMapping(name: "Home", folderPath: NSHomeDirectory()) { _, _ in }
    }
    
    @objc func createDocumentsTerminal() {
        let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        terminalManager.createWindowWithMapping(name: "Documents", folderPath: docsPath) { _, _ in }
    }
    
    @objc func createProjectTerminal() {
        // Launch the full terminal creator app
        let task = Process()
        task.launchPath = "/Users/lukekist/.terminal_creator/TerminalCreator"
        try? task.run()
    }
    
    @objc func focusTerminal(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? String else { return }
        terminalManager.focusTerminal(windowID: windowID)
    }
    
    @objc func renameTerminal(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? String else { return }
        
        let alert = NSAlert()
        alert.messageText = "Rename Terminal"
        alert.informativeText = "Enter new name for terminal \(windowID):"
        alert.alertStyle = .informational
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue
            if !newName.isEmpty {
                terminalManager.renameTerminal(windowID: windowID, name: newName)
            }
        }
    }
    
    @objc func closeTerminal(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? String else { return }
        terminalManager.closeTerminal(windowID: windowID)
    }
    
    @objc func renameCurrentTerminal() {
        let task = Process()
        task.launchPath = "/Users/lukekist/rename-terminal.sh"
        task.arguments = ["-c"]
        try? task.run()
    }
    
    @objc func renameAllTerminals() {
        let task = Process()
        task.launchPath = "/Users/lukekist/.local/bin/rename-all-terminals"
        try? task.run()
    }
    
    @objc func applyProjectNaming() {
        terminalManager.applyNamingScheme(.project)
    }
    
    @objc func applyFunctionNaming() {
        terminalManager.applyNamingScheme(.function)
    }
    
    @objc func applyWorkspaceNaming() {
        terminalManager.applyNamingScheme(.workspace)
    }
    
    @objc func screenshotToTerminal() {
        hoodrobotIntegration.captureScreenshotToTerminal()
    }
    
    @objc func sendFileToTerminal() {
        hoodrobotIntegration.sendFileToCurrentTerminal()
    }
    
    @objc func captureTerminalOutput() {
        hoodrobotIntegration.captureCurrentTerminalOutput()
    }
    
    @objc func toggleFocusIndicators() {
        hoodrobotIntegration.toggleFocusIndicators()
    }
    
    @objc func showStatistics() {
        hoodrobotIntegration.showTerminalStatistics()
    }
    
    @objc func openSettings() {
        // Open settings window
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Terminal Manager Settings"
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func openGitHub() {
        if let url = URL(string: "https://github.com/AgewellEPM/terminal-manager-system") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func createTerminalIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        
        // Draw terminal icon
        NSColor.labelColor.setFill()
        let rect = NSRect(x: 2, y: 2, width: 14, height: 14)
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        path.fill()
        
        NSColor.textBackgroundColor.setFill()
        let innerRect = NSRect(x: 3, y: 3, width: 12, height: 12)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 1, yRadius: 1)
        innerPath.fill()
        
        // Draw prompt
        NSColor.labelColor.setStroke()
        let promptPath = NSBezierPath()
        promptPath.move(to: NSPoint(x: 5, y: 9))
        promptPath.line(to: NSPoint(x: 8, y: 9))
        promptPath.lineWidth = 1.5
        promptPath.stroke()
        
        image.unlockFocus()
        return image
    }
}

// MARK: - Terminal Manager
class TerminalManager {
    struct Terminal {
        let id: String
        let name: String
    }
    
    enum NamingScheme {
        case project
        case function
        case workspace
    }
    
    func getAllTerminals() -> [Terminal] {
        let script = """
        tell application "Terminal"
            set terminalList to {}
            repeat with w in windows
                set windowID to id of w as string
                try
                    set windowName to custom title of w
                on error
                    set windowName to "Terminal " & windowID
                end try
                set end of terminalList to {id:windowID, name:windowName}
            end repeat
            return terminalList
        end tell
        """
        
        guard let result = executeAppleScript(script) else { return [] }
        
        // Parse the result
        var terminals: [Terminal] = []
        let lines = result.components(separatedBy: ",")
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let id = parts[0].trimmingCharacters(in: .whitespaces)
                let name = parts[1].trimmingCharacters(in: .whitespaces)
                terminals.append(Terminal(id: id, name: name))
            }
        }
        
        return terminals
    }
    
    func createNewTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script ""
        end tell
        """
        executeAppleScript(script)
    }
    
    func createWindowWithMapping(name: String, folderPath: String, completion: @escaping (Bool, String?) -> Void) {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(folderPath)'"
            set newWindowID to id of front window
            set custom title of front window to "\(name)"
            return newWindowID as string
        end tell
        """
        
        DispatchQueue.global().async {
            if let windowID = self.executeAppleScript(script) {
                self.saveMapping(windowID: windowID, name: name, path: folderPath)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Failed to create terminal")
                }
            }
        }
    }
    
    func focusTerminal(windowID: String) {
        let script = """
        tell application "Terminal"
            activate
            set frontmost of window id \(windowID) to true
        end tell
        """
        executeAppleScript(script)
    }
    
    func renameTerminal(windowID: String, name: String) {
        let script = """
        tell application "Terminal"
            set custom title of window id \(windowID) to "\(name)"
        end tell
        """
        executeAppleScript(script)
        saveMapping(windowID: windowID, name: name, path: "")
    }
    
    func closeTerminal(windowID: String) {
        let script = """
        tell application "Terminal"
            close window id \(windowID)
        end tell
        """
        executeAppleScript(script)
    }
    
    func applyNamingScheme(_ scheme: NamingScheme) {
        let terminals = getAllTerminals()
        
        switch scheme {
        case .project:
            for (index, terminal) in terminals.enumerated() {
                renameTerminal(windowID: terminal.id, name: "Project-\(index + 1)")
            }
        case .function:
            let names = ["Main", "Development", "Testing", "Documentation", "Build", "Debug", "Production", "Staging", "Research", "Support"]
            for (index, terminal) in terminals.enumerated() {
                let name = index < names.count ? names[index] : "Terminal-\(index + 1)"
                renameTerminal(windowID: terminal.id, name: name)
            }
        case .workspace:
            let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
            for (index, terminal) in terminals.enumerated() {
                let letter = index < letters.count ? letters[index] : String(index + 1)
                renameTerminal(windowID: terminal.id, name: "Workspace-\(letter)")
            }
        }
    }
    
    private func saveMapping(windowID: String, name: String, path: String) {
        // Save to TinkyBink mapping files
        let mappingFile = URL(fileURLWithPath: NSString(string: "~/.tinkybink_terminal_mappings.json").expandingTildeInPath)
        
        do {
            var mappings: [String: String] = [:]
            
            if let data = try? Data(contentsOf: mappingFile),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                mappings = existing
            }
            
            mappings[windowID] = name
            
            let data = try JSONSerialization.data(withJSONObject: mappings, options: .prettyPrinted)
            try data.write(to: mappingFile)
        } catch {
            print("Failed to save mapping: \(error)")
        }
    }
    
    @discardableResult
    private func executeAppleScript(_ script: String) -> String? {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}

// MARK: - Hoodrobot Integration
class HoodrobotIntegration {
    func isHoodrobotRunning() -> Bool {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", "pgrep -f Hoodrobot"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return !data.isEmpty
        } catch {
            return false
        }
    }
    
    func captureScreenshotToTerminal() {
        let process = Process()
        process.launchPath = "/Users/lukekist/Hoodrobot"
        process.arguments = ["--screenshot-to-terminal"]
        try? process.run()
    }
    
    func sendFileToCurrentTerminal() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            let process = Process()
            process.launchPath = "/Users/lukekist/Hoodrobot"
            process.arguments = ["--send-file", url.path]
            try? process.run()
        }
    }
    
    func captureCurrentTerminalOutput() {
        let process = Process()
        process.launchPath = "/Users/lukekist/Hoodrobot"
        process.arguments = ["--capture-output"]
        try? process.run()
    }
    
    func toggleFocusIndicators() {
        let process = Process()
        process.launchPath = "/Users/lukekist/Hoodrobot"
        process.arguments = ["--toggle-focus"]
        try? process.run()
    }
    
    func showTerminalStatistics() {
        // Create statistics window
        let alert = NSAlert()
        alert.messageText = "Terminal Statistics"
        
        // Get terminal count
        let manager = TerminalManager()
        let terminals = manager.getAllTerminals()
        
        alert.informativeText = """
        Active Terminals: \(terminals.count)
        Hoodrobot Status: Running
        Mappings Saved: \(getMappingsCount())
        """
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func getMappingsCount() -> Int {
        let mappingFile = URL(fileURLWithPath: NSString(string: "~/.tinkybink_terminal_mappings.json").expandingTildeInPath)
        
        guard let data = try? Data(contentsOf: mappingFile),
              let mappings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return 0
        }
        
        return mappings.count
    }
}