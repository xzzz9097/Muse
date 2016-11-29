//
//  AppleScriptBridge.swift
//  Muse
//
//  Created by Marco Albera on 29/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Foundation

class AppleScriptBridge {
    
    // Singleton constructor
    static let shared = AppleScriptBridge()
    
    // Make standard init private
    private init() {}
    
    func execAppleScript(_ script: String) {
        // Exec AppleScript without output return
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func setAppleScriptVariable(_ preScript: [String], _ value: String) {
        // Exec AppleScript to set a variable
        // preScript format: ["tell application \"\"\nset 'variable' to ","\nend tell"]
        var error: NSDictionary?
        
        let script = preScript[0] + value + preScript[1]
        
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func execAppleScriptWithOutput(_ script: String) -> String? {
        // Exec AppleScript with output return
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: script) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            
            if (output.stringValue != nil) {
                return output.stringValue
            }
        }
        
        return nil
    }
    
}
