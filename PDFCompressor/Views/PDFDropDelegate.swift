//
//  PDFDropDelegate.swift
//  PDFCompressor
//
//  Drag and drop support for PDF files
//

import SwiftUI

struct PDFDropDelegate: DropDelegate {
    @Binding var isDragging: Bool
    let onDrop: (URL) -> Void
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.pdf"])
    }
    
    func dropEntered(info: DropInfo) {
        isDragging = true
    }
    
    func dropExited(info: DropInfo) {
        isDragging = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        
        guard let itemProvider = info.itemProviders(for: ["public.pdf"]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.pdf", options: nil) { (data, error) in
            DispatchQueue.main.async {
                if let url = data as? URL {
                    self.onDrop(url)
                }
            }
        }
        
        return true
    }
}
