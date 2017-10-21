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
    
    fileprivate enum CellIndentifier {
        static let name = "NameCell"
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        
        var text = ""
        
        switch identifier {
        case CellIndentifier.name:
            text = trackSearchResults[row].name
        default: break
        }
        
        if let cell = tableView.make(withIdentifier: identifier, owner: self) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.textField?.textColor   = colors[1]
            
            return cell
        }
        
        return nil
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
            self?.resultsTableView.reloadData()
        }
    }
}
