//
//  PDFCompressor.swift
//  PDFCompressor
//
//  Core PDF compression with extreme compression support
//

import PDFKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

final class PDFCompressor {
    
    static let shared = PDFCompressor()
    
    // MARK: - Compression Levels for any target size
    private struct CompressionLevel {
        let quality: CGFloat
        let maxDimension: CGFloat
        let grayscale: Bool
        let description: String
    }
    
    private let compressionLevels: [CompressionLevel] = [
        CompressionLevel(quality: 1.0, maxDimension: 3000, grayscale: false, description: "Original"),
        CompressionLevel(quality: 0.7, maxDimension: 2000, grayscale: false, description: "High"),
        CompressionLevel(quality: 0.5, maxDimension: 1500, grayscale: false, description: "Medium"),
        CompressionLevel(quality: 0.3, maxDimension: 1000, grayscale: false, description: "Low"),
        CompressionLevel(quality: 0.2, maxDimension: 800, grayscale: false, description: "Very Low"),
        CompressionLevel(quality: 0.15, maxDimension: 600, grayscale: false, description: "Extreme"),
        CompressionLevel(quality: 0.1, maxDimension: 500, grayscale: false, description: "Maximum"),
        CompressionLevel(quality: 0.1, maxDimension: 400, grayscale: true, description: "Grayscale"),
        CompressionLevel(quality: 0.08, maxDimension: 300, grayscale: true, description: "Tiny")
    ]
    
    func compress(
        pdfURL: URL,
        settings: CompressionSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> CompressionResult {
        
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw CompressionError.invalidPDF
        }
        
        guard pdfDocument.pageCount > 0 else {
            throw CompressionError.noPages
        }
        
        let originalData = try Data(contentsOf: pdfURL)
        let originalSize = originalData.count
        
        let startTime = Date()
        
        var outputURL: URL
        var qualityUsed: CompressionQuality? = nil
        
        switch settings.mode {
        case .targetSize:
            (outputURL, qualityUsed) = try await compressForTargetSize(
                pdfDocument: pdfDocument,
                originalSize: originalSize,
                targetSize: settings.targetSizeBytes,
                progressHandler: progressHandler
            )
        case .percentage:
            (outputURL, qualityUsed) = try await compressForPercentage(
                pdfDocument: pdfDocument,
                percentage: settings.percentageReduction,
                progressHandler: progressHandler
            )
        case .quality:
            outputURL = try await compressWithLevel(
                pdfDocument: pdfDocument,
                quality: settings.quality,
                progressHandler: progressHandler
            )
            qualityUsed = settings.quality
        }
        
        let compressedData = try Data(contentsOf: outputURL)
        let finalSize = compressedData.count
        let duration = Date().timeIntervalSince(startTime)
        
        await MainActor.run {
            progressHandler(1.0)
        }
        
        return CompressionResult(
            originalSize: originalSize,
            compressedSize: finalSize,
            outputURL: outputURL,
            duration: duration,
            qualityUsed: qualityUsed
        )
    }
    
    // MARK: - Target Size Compression (Any size achievable)
    private func compressForTargetSize(
        pdfDocument: PDFDocument,
        originalSize: Int,
        targetSize: Int,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (URL, CompressionQuality?) {
        
        // Try each compression level until we hit target
        var bestURL: URL? = nil
        var bestSize = originalSize
        var bestQuality: CompressionQuality? = nil
        
        for (index, level) in compressionLevels.enumerated() {
            await MainActor.run {
                progressHandler(Double(index) / Double(compressionLevels.count) * 0.9)
            }
            
            do {
                let testURL = try await compressWithLevelRaw(
                    pdfDocument: pdfDocument,
                    quality: level.quality,
                    maxDimension: level.maxDimension,
                    grayscale: level.grayscale,
                    progressHandler: { _ in }
                )
                
                let testData = try Data(contentsOf: testURL)
                let testSize = testData.count
                
                // Update best if smaller and under target
                if testSize <= targetSize && testSize < bestSize {
                    if let old = bestURL { try? FileManager.default.removeItem(at: old) }
                    bestURL = testURL
                    bestSize = testSize
                    bestQuality = qualityFromLevel(index)
                    
                    // Close enough to target?
                    let ratio = Double(testSize) / Double(targetSize)
                    if ratio > 0.7 {
                        break
                    }
                } else if testSize < bestSize {
                    if let old = bestURL, bestSize > targetSize { try? FileManager.default.removeItem(at: old) }
                    if bestURL == nil || bestSize > targetSize {
                        bestURL = testURL
                        bestSize = testSize
                        bestQuality = qualityFromLevel(index)
                    } else {
                        try? FileManager.default.removeItem(at: testURL)
                    }
                } else {
                    try? FileManager.default.removeItem(at: testURL)
                }
                
            } catch {
                continue
            }
        }
        
        guard let result = bestURL else {
            throw CompressionError.compressionFailed
        }
        
        return (result, bestQuality)
    }
    
    // MARK: - Percentage Compression
    private func compressForPercentage(
        pdfDocument: PDFDocument,
        percentage: Double,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (URL, CompressionQuality?) {
        
        let reduction = max(0, min(100, percentage)) / 100.0
        
        // Map percentage to compression level
        let levelIndex: Int
        if reduction < 0.2 {
            levelIndex = 0
        } else if reduction < 0.4 {
            levelIndex = 1
        } else if reduction < 0.5 {
            levelIndex = 2
        } else if reduction < 0.6 {
            levelIndex = 3
        } else if reduction < 0.7 {
            levelIndex = 4
        } else if reduction < 0.8 {
            levelIndex = 5
        } else if reduction < 0.9 {
            levelIndex = 6
        } else {
            levelIndex = 7
        }
        
        let level = compressionLevels[min(levelIndex, compressionLevels.count - 1)]
        
        let url = try await compressWithLevelRaw(
            pdfDocument: pdfDocument,
            quality: level.quality,
            maxDimension: level.maxDimension,
            grayscale: level.grayscale,
            progressHandler: progressHandler
        )
        
        let quality = qualityFromLevel(levelIndex)
        return (url, quality)
    }
    
    // MARK: - Quality-based Compression
    private func compressWithLevel(
        pdfDocument: PDFDocument,
        quality: CompressionQuality,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        let level: CompressionLevel
        switch quality {
        case .maximum:
            level = compressionLevels[0]
        case .high:
            level = compressionLevels[1]
        case .medium:
            level = compressionLevels[2]
        case .low:
            level = compressionLevels[3]
        case .extreme:
            level = compressionLevels[6]
        }
        
        return try await compressWithLevelRaw(
            pdfDocument: pdfDocument,
            quality: level.quality,
            maxDimension: level.maxDimension,
            grayscale: level.grayscale,
            progressHandler: progressHandler
        )
    }
    
    private func compressWithLevelRaw(
        pdfDocument: PDFDocument,
        quality: CGFloat,
        maxDimension: CGFloat,
        grayscale: Bool,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> URL {
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        
        let newPDF = PDFDocument()
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            
            await MainActor.run {
                progressHandler(Double(i + 1) / Double(pageCount) * 0.9)
            }
            
            let compressedPage = try await compressPage(
                page: page,
                qualityFactor: quality,
                maxDimension: maxDimension,
                grayscale: grayscale
            )
            
            newPDF.insert(compressedPage, at: newPDF.pageCount)
        }
        
        guard newPDF.write(to: outputURL) else {
            throw CompressionError.saveFailed
        }
        
        return outputURL
    }
    
    private func compressPage(
        page: PDFPage,
        qualityFactor: CGFloat,
        maxDimension: CGFloat,
        grayscale: Bool
    ) async throws -> PDFPage {
        
        let bounds = page.bounds(for: .mediaBox)
        
        // Skip compression for max quality
        if qualityFactor >= 1.0 && maxDimension >= 3000 {
            return (page.copy() as? PDFPage) ?? page
        }
        
        // Calculate scale
        let maxPageDim = max(bounds.width, bounds.height)
        let scale = maxPageDim > maxDimension ? maxDimension / maxPageDim : 1.0
        
        // Render
        let renderSize = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
        
        guard let image = renderPageToImage(page: page, size: renderSize) else {
            return (page.copy() as? PDFPage) ?? page
        }
        
        // Compress
        guard let compressedImage = compressImage(image, quality: qualityFactor, grayscale: grayscale) else {
            return PDFPage(image: image) ?? page
        }
        
        guard let newPage = PDFPage(image: compressedImage) else {
            return page
        }
        
        return newPage
    }
    
    private func renderPageToImage(page: PDFPage, size: CGSize) -> NSImage? {
        return page.thumbnail(of: size, for: .mediaBox)
    }
    
    private func compressImage(_ image: NSImage, quality: CGFloat, grayscale: Bool) -> NSImage? {
        guard let tiffData = image.tiffRepresentation else { return nil }
        guard let source = CGImageSourceCreateWithData(tiffData as CFData, nil) else { return nil }
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        
        let finalQuality = max(0.05, min(1.0, quality))
        
        var options: [NSString: Any] = [
            kCGImageDestinationLossyCompressionQuality: finalQuality
        ]
        
        if grayscale {
            options[kCGImagePropertyColorModel] = "Gray"
            options[kCGImagePropertyDepth] = 8
        }
        
        guard let mutableData = CFDataCreateMutable(nil, 0) else { return nil }
        
        let utType = UTType.jpeg.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(mutableData, utType, 1, nil) else { return nil }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        guard let jpegData = mutableData as Data? else { return nil }
        return NSImage(data: jpegData)
    }
    
    private func qualityFromLevel(_ index: Int) -> CompressionQuality? {
        switch index {
        case 0: return .maximum
        case 1: return .high
        case 2: return .medium
        case 3, 4: return .low
        case 5, 6, 7, 8: return .extreme
        default: return nil
        }
    }
    
    func saveCompressedPDF(from url: URL, to destination: URL) throws {
        let data = try Data(contentsOf: url)
        try data.write(to: destination)
    }
}
