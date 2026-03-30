//
//  CompressorViewModel.swift
//  PDFCompressor
//
//  Main view model handling compression logic and state
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class CompressorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedFileURL: URL?
    @Published var originalFileSize: Int = 0
    @Published var isCompressing: Bool = false
    @Published var compressionProgress: Double = 0
    @Published var compressionResult: CompressionResult?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSaveDialog: Bool = false
    @Published var previewPDF: PDFDocument?
    
    // MARK: - Settings
    @Published var settings = CompressionSettings()
    
    // MARK: - Computed Properties
    var originalSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalFileSize), countStyle: .file)
    }
    
    var hasSelectedFile: Bool {
        selectedFileURL != nil
    }
    
    var canCompress: Bool {
        hasSelectedFile && !isCompressing
    }
    
    var estimatedSizeString: String {
        let estimatedBytes: Int
        switch settings.mode {
        case .percentage:
            let reduction = 1.0 - (settings.percentageReduction / 100.0)
            estimatedBytes = Int(Double(originalFileSize) * reduction)
        case .targetSize:
            estimatedBytes = settings.targetSizeBytes
        case .quality:
            let qualityFactor = settings.quality.cgFloat
            estimatedBytes = Int(Double(originalFileSize) * (0.2 + 0.8 * qualityFactor))
        }
        return ByteCountFormatter.string(fromByteCount: Int64(max(estimatedBytes, 1024)), countStyle: .file)
    }
    
    var targetSizeAchievable: Bool {
        if settings.mode != .targetSize { return true }
        // Rough estimate: can achieve ~2% of original size in extreme mode
        let minAchievable = Double(originalFileSize) * 0.02
        return Double(settings.targetSizeBytes) >= minAchievable
    }
    
    var minTargetSizeMB: Double {
        let minBytes = Double(originalFileSize) * 0.02
        return max(0.1, minBytes / (1024 * 1024))
    }
    
    // MARK: - Methods
    
    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.pdf]
        
        panel.beginSheetModal(for: NSApp.mainWindow!) { [weak self] result in
            guard let self = self else { return }
            
            if result == .OK, let url = panel.url {
                Task { @MainActor in
                    await self.loadFile(url: url)
                }
            }
        }
    }
    
    func loadFile(url: URL) async {
        selectedFileURL = url
        compressionResult = nil
        
        do {
            let data = try Data(contentsOf: url)
            originalFileSize = data.count
            previewPDF = PDFDocument(url: url)
        } catch {
            showError(message: "Failed to load PDF: \(error.localizedDescription)")
        }
    }
    
    func compressPDF() {
        guard let url = selectedFileURL else { return }
        
        isCompressing = true
        compressionProgress = 0
        compressionResult = nil
        
        Task {
            do {
                let result = try await PDFCompressor.shared.compress(
                    pdfURL: url,
                    settings: settings
                ) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.compressionProgress = progress
                    }
                }
                
                self.compressionResult = result
                self.isCompressing = false
                self.showSaveDialog = true
                
            } catch let error as CompressionError {
                isCompressing = false
                showError(message: error.localizedDescription)
            } catch {
                isCompressing = false
                showError(message: "Compression failed: \(error.localizedDescription)")
            }
        }
    }
    
    func saveCompressedFile() {
        guard let result = compressionResult else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = generateOutputFilename()
        
        panel.beginSheetModal(for: NSApp.mainWindow!) { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let url = panel.url {
                do {
                    try PDFCompressor.shared.saveCompressedPDF(from: result.outputURL, to: url)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    self.showError(message: "Failed to save: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func reset() {
        selectedFileURL = nil
        originalFileSize = 0
        compressionResult = nil
        compressionProgress = 0
        previewPDF = nil
        settings = CompressionSettings()
    }
    
    private func generateOutputFilename() -> String {
        guard let original = selectedFileURL else {
            return "compressed.pdf"
        }
        
        let name = original.deletingPathExtension().lastPathComponent
        let suffix: String
        
        switch settings.mode {
        case .percentage:
            suffix = "\(Int(settings.percentageReduction))pct"
        case .targetSize:
            suffix = "\(String(format: "%.1f", settings.targetSizeMB))MB"
        case .quality:
            if let quality = compressionResult?.qualityUsed {
                suffix = quality.rawValue.lowercased().replacingOccurrences(of: " (", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "_")
            } else {
                suffix = settings.quality.rawValue.lowercased().replacingOccurrences(of: " (", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "_")
            }
        }
        
        return "\(name)_\(suffix).pdf"
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
