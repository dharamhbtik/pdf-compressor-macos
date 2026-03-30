//
//  ContentView.swift
//  PDFCompressor
//
//  Professional main application interface
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @StateObject private var viewModel = CompressorViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Left panel: Controls
            controlPanel
                .frame(width: 380)
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Right panel: Preview
            previewPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.textBackgroundColor))
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.reset()
                } label: {
                    Label("New", systemImage: "doc.badge.plus")
                }
                .disabled(viewModel.selectedFileURL == nil && !viewModel.isCompressing)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    
    // MARK: - Control Panel
    private var controlPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                
                // File Selection
                fileSection
                
                // Compression Settings
                settingsSection
                
                // Action Button
                actionSection
                
                Spacer(minLength: 20)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PDF Compressor")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("Professional PDF Size Optimization")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "doc.fill", title: "Source File")
            
            if let url = viewModel.selectedFileURL {
                FileInfoCard(
                    filename: url.lastPathComponent,
                    path: url.path,
                    size: viewModel.originalSizeString,
                    onChange: { viewModel.selectFile() }
                )
            } else {
                DropZone(onTap: { viewModel.selectFile() })
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.controlBackgroundColor).opacity(0.4))
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(icon: "gearshape.2.fill", title: "Compression Settings")
            
            // Mode Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.settings.mode) {
                    ForEach(CompressionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Mode-specific controls
            Group {
                switch viewModel.settings.mode {
                case .percentage:
                    percentageControl
                case .targetSize:
                    targetSizeControl
                case .quality:
                    qualityControl
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Advanced Options
            AdvancedOptions(settings: $viewModel.settings)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    private var percentageControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reduce by")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(viewModel.settings.percentageReduction))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estimated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.estimatedSizeString)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Slider(value: $viewModel.settings.percentageReduction, in: 10...95, step: 5)
                .tint(.blue)
        }
    }
    
    private var targetSizeControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Size")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(String(format: "%.1f", viewModel.settings.targetSizeMB))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text("MB")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !viewModel.targetSizeAchievable {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label("Too small", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Min: \(String(format: "%.1f", viewModel.minTargetSizeMB)) MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Slider(
                value: $viewModel.settings.targetSizeMB,
                in: max(0.1, viewModel.minTargetSizeMB)...max(viewModel.minTargetSizeMB * 10, 10),
                step: 0.5
            )
            .tint(viewModel.targetSizeAchievable ? .blue : .orange)
            
            Text("Will compress to reach target size, even at very low quality if needed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var qualityControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quality Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $viewModel.settings.quality) {
                    ForEach(CompressionQuality.allCases) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .pickerStyle(.menu)
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: qualityIcon(for: viewModel.settings.quality))
                    .font(.title2)
                    .foregroundColor(qualityColor(for: viewModel.settings.quality))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.settings.quality.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if viewModel.hasSelectedFile {
                        Text("Estimated: ~\(viewModel.estimatedSizeString)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func qualityIcon(for quality: CompressionQuality) -> String {
        switch quality {
        case .extreme: return "photo.fill"
        case .low: return "photo"
        case .medium: return "photo.on.rectangle"
        case .high: return "photo.on.rectangle.angled"
        case .maximum: return "doc.richtext.fill"
        }
    }
    
    private func qualityColor(for quality: CompressionQuality) -> Color {
        switch quality {
        case .extreme: return .red
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .blue
        case .maximum: return .green
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            if viewModel.isCompressing {
                CompressionProgressView(
                    progress: viewModel.compressionProgress,
                    label: "Compressing PDF..."
                )
            } else if let result = viewModel.compressionResult {
                CompressionSuccessView(
                    result: result,
                    onSave: { viewModel.saveCompressedFile() }
                )
            } else {
                Button {
                    viewModel.compressPDF()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Compress PDF")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!viewModel.canCompress)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    // MARK: - Preview Panel
    private var previewPanel: some View {
        VStack(spacing: 0) {
            if let pdf = viewModel.previewPDF {
                PDFPreviewHeader(document: pdf, fileURL: viewModel.selectedFileURL)
                
                PDFKitView(document: pdf)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyStateView(onBrowse: { viewModel.selectFile() })
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct FileInfoCard: View {
    let filename: String
    let path: String
    let size: String
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(filename)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .help(path)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "externaldrive.fill")
                            .font(.caption)
                        Text(size)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Change") {
                    onChange()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct DropZone: View {
    let onTap: () -> Void
    @State private var isDragging = false
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue.opacity(isDragging ? 1.0 : 0.6))
                
                VStack(spacing: 4) {
                    Text("Drop PDF here or click to browse")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    
                    Text("Supports drag & drop from Finder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundColor(isDragging ? .blue : .secondary.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(isDragging ? 0.1 : 0.02))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct AdvancedOptions: View {
    @Binding var settings: CompressionSettings
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Advanced Options")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $settings.downsampleImages) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Downsample images")
                                .font(.subheadline)
                            Text("Reduce image resolution")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if settings.downsampleImages {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Max dimension: \(Int(settings.maxImageDimension))px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: $settings.maxImageDimension, in: 300...3000, step: 100)
                                .tint(.blue)
                        }
                        .padding(.leading, 24)
                    }
                    
                    Toggle(isOn: $settings.compressFonts) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Optimize fonts")
                                .font(.subheadline)
                            Text("Subset and compress font data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.removeMetadata) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remove metadata")
                                .font(.subheadline)
                            Text("Strip document properties and EXIF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct CompressionProgressView: View {
    let progress: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .progressViewStyle(.linear)
            .tint(.blue)
            
            HStack {
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct CompressionSuccessView: View {
    let result: CompressionResult
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compression Complete!")
                        .font(.headline)
                    
                    Text("Took \(String(format: "%.1f", result.duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                SizeComparisonItem(label: "Original", size: result.originalSizeString, color: .secondary)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                SizeComparisonItem(label: "Compressed", size: result.compressedSizeString, color: .green)
            }
            .padding(.vertical, 4)
            
            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: result.achievedTarget ? "arrow.down.circle.fill" : "exclamationmark.triangle.fill")
                    Text("\(Int(result.reductionPercentage))% smaller")
                        .fontWeight(.semibold)
                }
                .font(.title3)
                .foregroundColor(result.achievedTarget ? .green : .orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(result.achievedTarget ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                )
                
                Spacer()
            }
            
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save Compressed PDF")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct SizeComparisonItem: View {
    let label: String
    let size: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(size)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct PDFPreviewHeader: View {
    let document: PDFDocument
    let fileURL: URL?
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                
                Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let url = fileURL {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.windowBackgroundColor))
    }
}

struct EmptyStateView: View {
    let onBrowse: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("No PDF Selected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select a PDF file to preview and compress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    onBrowse()
                } label: {
                    Label("Browse Files", systemImage: "folder")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PDFKit View Representable

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        pdfView.enclosingScrollView?.hasVerticalScroller = true
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
