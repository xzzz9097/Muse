//
//  AppDelegate.swift
//  Muse
//
//  Created by Marco Albera on 21/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa
import MASPreferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier!
    }
    
    // MARK: Properties
    
    let menuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // TODO: do this without callbacks!
    
    var windowToggledHandler: () -> () = { }

    // MARK: Outlets
    
    @IBOutlet weak var menuBarMenu: NSMenu!
    
    // MARK: Actions
    
    @IBAction func toggleWindowMenuItemClicked(_ sender: Any) {
        // Show window
        windowToggledHandler()
    }
    
    @IBAction func quitMenuItemClicked(_ sender: Any) {
        // Quit the application
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func preferencesMenuItemClicked(_ sender: Any) {
        preferencesWindowController.showWindow(self)
    }
    
    @IBAction func customizeTouchBar(_ sender: NSMenuItem) {
        if #available(OSX 10.12.2, *) { NSApp.toggleTouchBarCustomizationPalette(self) }
    }
    
    // MARK: Preferences
    
    let preferencesWindowController: NSWindowController = MASPreferencesWindowController(viewControllers: [GeneralPreferencesViewController(), AccountsPreferencesViewController()])
    
    // MARK: Data saving
    
    private static var supportFiles = [String]()
    
    var bundleFilesURLs = supportFiles.map { file -> URL in
        let res = String.init(file.split(separator: ".")[0])
        let ext = String.init(file.split(separator: ".")[1])
        
        return Bundle.main.url(forResource: res, withExtension: ext)!
    }
    
    static var supportFilesURLs = supportFiles.map { file -> URL in
        return applicationSupportURL!.appendingPathComponent("/\(file)")
    }
    
    static var applicationSupportURL: URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask,
            true
        ).first else { return nil }
        
        return NSURL(fileURLWithPath: path).appendingPathComponent(bundleIdentifier)
    }
    
    /**
     Checks if application support folder is present.
     http://www.cocoabuilder.com/archive/cocoa/281310-creating-an-application-support-folder.html
     */
    var hasApplicationSupportFolder: Bool {
        guard let url = AppDelegate.applicationSupportURL else { return false }
        
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path,
                                                    isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
    
    /**
     Checks if application support files are present.
     */
     var hasApplicationSupportFiles: Bool {
        guard let url = AppDelegate.applicationSupportURL else { return false }
        
        let filesExist = AppDelegate.supportFiles.map { file in
            return FileManager.default
                .fileExists(atPath: url.appendingPathComponent(file).path)
        }
        
        return !filesExist.contains(false)
    }
    
    func createApplicationSupportFolder() {
        guard let url = AppDelegate.applicationSupportURL else { return }
        
        do {
            try FileManager.default.createDirectory(at: url,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
        } catch {
            // Application support folder can't be created
        }
    }
    
    /**
     Copies support files to application folder
     */
    func copyApplicationSupportFiles() {
        guard let url = AppDelegate.applicationSupportURL else { return }
        
        bundleFilesURLs.forEach { fileURL in
            let destination = url.path.appending("/\(fileURL.lastPathComponent)")
            
            do {
                try FileManager.default.copyItem(atPath: fileURL.path,
                                                 toPath: destination)
            } catch {
                // Can't copy support files
            }
        }
    }
    
    // MARK: Functions
    
    func attachMenuItem() {
        // Set the menu for the item
        menuItem.menu = menuBarMenu
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Enable TouchBar overlay if 10.12.2
        if #available(OSX 10.12.2, *) {
            NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        }
        
        // Create the menu item
        attachMenuItem()
        
        // Register dafault user preferences
        registerDefaultPreferences()
    }
    
    func registerDefaultPreferences() {
        PreferenceKey.registerDefaults()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

