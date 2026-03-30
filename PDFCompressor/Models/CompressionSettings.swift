//
//  CompressionSettings.swift
//  PDFCompressor
//
//  Model for compression configuration
//

import Foundation

enum CompressionMode: String, CaseIterable, Identifiable {
    case percentage = "Percentage"
    case targetSize = "Target Size"
    case quality = "Quality Level"
    
    var id: String { self.rawValue }
}

enum CompressionQuality: String, CaseIterable, Identifiable {
    case extreme = "Extreme (Tiny)"
    case low = "Low (Smaller)"
    case medium = "Medium (Balanced)"
    case high = "High (Better)"
    case maximum = "Maximum (Original)"
    
    var id: String { self.rawValue }
    
    var cgFloat: CGFloat {
        switch self {
        case .extreme: return 0.1
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .maximum: return 1.0
        }
    }
    
    var description: String {
        switch self {
        case .extreme: return "Maximum compression, smallest size, lowest quality"
        case .low: return "Aggressive compression, smaller file size"
        case .medium: return "Balanced compression and quality"
        case .high: return "Minimal compression, better quality"
        case .maximum: return "No image compression, best quality"
        }
    }
    
    var maxDimension: Double {
        switch self {
        case .extreme: return 400
        case .low: return 800
        case .medium: return 1200
        case .high: return 2000
        case .maximum: return 5000
        }
    }
}

struct CompressionSettings {
    var mode: CompressionMode = .quality
    var percentageReduction: Double = 50
    var targetSizeMB: Double = 1.0
    var quality: CompressionQuality = .medium
    var downsampleImages: Bool = true
    var maxImageDimension: Double = 1200
    var removeMetadata: Bool = false
    var compressFonts: Bool = true
    
    var targetSizeBytes: Int {
        return Int(targetSizeMB * 1024 * 1024)
    }
}

struct CompressionResult {
    let originalSize: Int
    let compressedSize: Int
    let outputURL: URL
    let duration: TimeInterval
    let qualityUsed: CompressionQuality?
    
    var reductionPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - compressedSize) / Double(originalSize) * 100
    }
    
    var originalSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
    }
    
    var compressedSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressedSize), countStyle: .file)
    }
    
    var achievedTarget: Bool {
        return compressedSize < originalSize
    }
}

enum CompressionError: LocalizedError {
    case invalidPDF
    case noPages
    case compressionFailed
    case fileNotFound
    case targetSizeTooSmall
    case permissionDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF: return "Invalid PDF file"
        case .noPages: return "PDF has no pages"
        case .compressionFailed: return "Compression failed"
        case .fileNotFound: return "File not found"
        case .targetSizeTooSmall: return "Target size too small - try a larger size"
        case .permissionDenied: return "Permission denied"
        case .saveFailed: return "Failed to save compressed PDF"
        }
    }
}
