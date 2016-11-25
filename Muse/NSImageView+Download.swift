//
//  NSImageView+Download.swift
//  Muse
//
//  Created by Marco Albera on 24/11/16.
//  Copyright © 2016 Edge Apps. All rights reserved.
//

import Cocoa

extension NSImageView {

    func loadImageFromURL(url: URL) {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil && url != nil {
                if let data = NSData(contentsOf: url!) {
                    if let image = NSImage(data: data as Data) {
                        DispatchQueue.main.async(execute: {
                            
                            if let strongSelf = self {
                                strongSelf.image = image
                            }
                        })
                    }
                }
            }
        })
        
        downloadTask.resume()
    }
    
}
