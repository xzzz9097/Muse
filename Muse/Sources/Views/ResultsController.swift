//
//  ResultsController.swift
//  Muse
//
//  Created by Marco Albera on 26/07/2018.
//  Copyright © 2018 Edge Apps. All rights reserved.
//

import Cocoa

extension NSTableView {
    
    /**
     Reloads tableView data and highlights first entry
     */
    func reloadData(selectingFirst: Bool) {
        // Refresh table view data
        self.reloadData()
        
        // Scroll to the top
        self.scrollRowToVisible(0)
        
        // Automatically select first result
        self.selectRowIndexes([0], byExtendingSelection: false)
    }
    
    /**
     Reloads tableView data while keeping selection
     */
    func reloadData(keepingSelection: Bool) {
        // Save currently selected row
        let selectedRow = self.selectedRow
        
        // Refresh tableView data
        self.reloadData()
        
        // Restore previous selection
        self.selectRowIndexes([selectedRow], byExtendingSelection: false)
    }
}

extension NSTableView {
    /**
     The cell view at the requested index. Returns 0 if index is out of bounds.
     */
    func cell(at row: Int) -> ResultsTableCellView? {
        if row < 0 { return nil }
        
        return self.view(atColumn: 0, row: row, makeIfNecessary: true) as? ResultsTableCellView
    }
}

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDelegate {
    
    /**
     Table cell generation
     2 fields: result (track) name and author
     */
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        switch resultsMode {
        case .trackSearch:
            return searchTableView(tableView, viewFor: tableColumn, row: row)
        case .playlists:
            return playlistsTableView(tableView, viewFor: tableColumn, row: row)
        }
    }
    
    /**
     Specify custom row class for table view for personalized highlight color
     */
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return CustomHighLightTableRowView(fillColor: colors?.highlight)
    }
    
    /**
     Double click action, set as tableView.doubleAction
     */
    @objc func tableViewDoubleClicked(tableView: NSTableView) {
        switch resultsMode {
        case .trackSearch:
            searchTableViewDoubleClicked(tableView: tableView)
        case .playlists:
            playlistsTableViewDoubleClicked(tableView: tableView)
        }
    }
    
    /**
     Intercepts selection event to adapt text color to highlight.
     */
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let currentlySelectedCell = tableView.cell(at: tableView.selectedRow)
        
        // Restore original colors on previously selected cell
        currentlySelectedCell?.textField?.textColor       = colors?.primary
        currentlySelectedCell?.secondTextField?.textColor = colors?.designatedSecondary
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedCell = resultsTableView?.cell(at: resultsTableView?.selectedRow ?? -1)
        
        // Invert text colors on the newly selected cell to make it readable
        [ selectedCell?.textField, selectedCell?.secondTextField ].forEach {
            $0?.textColor = colors?.background
        }
    }
}

@available(OSX 10.12.2, *)
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch resultsMode {
        case .trackSearch:
            return searchNumberOfRows(in: tableView)
        case .playlists:
            return playlistsNumberOfRows(in: tableView)
        }
    }
}

@available(OSX 10.12.2, *)
extension ViewController {
    
    /**
     Text has been received from controlTextDidChange.
     Performs Spotify search query and set results array to the fetched results
     */
    func search(_ text: String) {
        switch resultsMode {
        case .trackSearch:
            searchTrack(text)
        case .playlists:
            searchPlaylist(text)
        }
    }
    @objc  
    func startSearch() {
        // Enable editing and empty the field
        titleTextField.isEditable  = true
        titleTextField.isEnabled   = true
        titleTextField.stringValue = ""
        
        // Make first responder -> start editing
        titleTextField.becomeFirstResponder()
        
        mainViewMode = .expandedWithResults
    }
    
    func endSearch(canceled: Bool = false) {
        // Disable editing
        titleTextField.isEditable  = false
        titleTextField.isEnabled   = false
        
        // Ensure that the text field has the right width
        titleTextField.animator().invalidateIntrinsicContentSize()
        
        if canceled {
            // Restore text to song title
            titleTextField.stringValue = titleLabelView.stringValue
        }
        
        // Restart the autoclose timer
        launchTitleViewAutoCloseTimer()
        
        // Hide results table after small delay
        DispatchQueue.main.run(after: canceled ? 0 : 750) { [weak self] in
            self?.mainViewMode = MainViewMode.defaultMode
        }
    }
}
