//
//  PlaylistsController.swift
//  Muse
//
//  Created by Marco Albera on 26/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Cocoa

// MARK: NSTableViewDelegate

@available(OSX 10.12.2, *)
extension ViewController {
    
    /**
     Table cell generation
     1 field: result (playlist) name
     */
    func playlistsTableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        
        if let cell = tableView.make(withIdentifier: identifier, owner: self) as? ResultsTableCellView {
            // First table cell field: playlist name
            cell.textField?.stringValue = playlistsResults[row].name
            cell.textField?.textColor   = colors?.primary
            
            // Second table cell field: blank
            cell.secondTextField?.stringValue = ""
            cell.secondTextField?.textColor   = colors?.designatedSecondary
            
            return cell
        }
        
        return nil
    }
    
    func playlistsTableViewDoubleClicked(tableView: NSTableView) {
    }
}

// MARK: NSTableViewDataSource

@available(OSX 10.12.2, *)
extension ViewController {
    
    func playlistsNumberOfRows(in tableView: NSTableView) -> Int {
        return playlistsResults.count
    }
}

// MARK: Playlist related functions

@available(OSX 10.12.2, *)
extension ViewController {
    
    func loadPlaylists() {
        if let helper = helper as? PlaylistablePlayerHelper {
            DispatchQueue.main.async { [weak self] in
                self?.playlistsResults = helper.playlists
                
                self?.resultsTableView?.reloadData(selectingFirst: true)
            }
        }
    }
    
    func startPlaylists() {
        guard helper is PlaylistablePlayerHelper else { return }
        
        // Switch results mode first
        resultsMode = .playlists
        
        // Preload the playlists
        loadPlaylists()
        
        mainViewMode = .expandedWithResults
    }
    
    func endPlaylists() {
        self.mainViewMode = .defaultMode
    }
}
