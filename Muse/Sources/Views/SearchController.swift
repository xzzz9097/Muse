//
//  SearchController.swift
//  Muse
//
//  Created by Marco Albera on 20/10/2017.
//  Copyright © 2017 Edge Apps. All rights reserved.
//

import Cocoa
import SpotifyKit

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDelegate {
    
    /**
     Table cell generation
     2 fields: result (track) name and author
     */
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        
        if let cell = tableView.make(withIdentifier: identifier, owner: self) as? ResultsTableCellView {
            // First table cell field: track name
            cell.textField?.stringValue = trackSearchResults[row].name
            cell.textField?.textColor   = colors[1]
            
            // Second table cell field: artist name
            cell.secondTextField?.stringValue = trackSearchResults[row].artist.name
            cell.secondTextField?.textColor   = colors[2]
            
            return cell
        }
        
        return nil
    }

    /**
     Specify custom row class for table view for personalized highlight color
     */
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {        
        return CustomHighLightTableRowView(fillColor: colors[3])
    }
    
    /**
     Double click action, set as tableView.doubleAction
     */
    func tableViewDoubleClicked(tableView: NSTableView) {
        if let spotifyHelper = helper as? SpotifyHelper, tableView.selectedRow >= 0 {
            spotifyHelper.play(uri: trackSearchResults[tableView.selectedRow].uri)
        }
    }
}

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return trackSearchResults.count
    }
}

@available(OSX 10.12.2, *)
extension ViewController {
    
    /**
     Text has been received from controlTextDidChange.
     Performs Spotify search query and set results array to the fetched results
     */
    func search(_ text: String) {
        spotifyManager.find(SpotifyTrack.self, text) { [weak self] tracks in
            self?.trackSearchResults = tracks
            
            // Refresh table view
            self?.resultsTableView?.reloadData()
            
            // Automatically select first result
            self?.resultsTableView?.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
}
