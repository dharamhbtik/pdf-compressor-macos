# PDF Compressor for macOS

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://developer.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A professional **macOS PDF compression app** built with SwiftUI that reduces PDF file size by up to **95%** using native Apple frameworks. No third-party libraries required.

## Features

- **Any Target Size** - Compress PDFs to any size from 5MB to 50KB
- **5 Quality Levels** - Maximum, High, Medium, Low, and Extreme compression
- **Native macOS UI** - Modern SwiftUI interface with drag & drop support
- **Live Preview** - Preview PDF before and after compression
- **100% Native** - Built with PDFKit, CoreGraphics, and ImageIO only
- **Fast & Efficient** - Multi-threaded compression with progress tracking

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)

### Build from Source

```bash
git clone https://github.com/yourusername/pdf-compressor-macos.git
cd pdf-compressor-macos
swift build
swift run PDFCompressor
```

Or open `Package.swift` in Xcode and run (⌘+R).

## Usage

1. **Select PDF** - Drag & drop or click "Browse" to select a PDF file
2. **Choose Mode**:
   - **Target Size** - Specify exact file size (e.g., 500KB, 1MB)
   - **Percentage** - Reduce by percentage (e.g., 80% smaller)
   - **Quality** - Select preset quality level
3. **Compress** - Click "Compress PDF" button
4. **Save** - Download your optimized PDF

## Compression Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **Target Size** | Reach exact file size | Email attachments, upload limits |
| **Percentage** | Reduce by % | Quick compression |
| **Quality** | 5 preset levels | Fine-tuned control |

### Quality Levels

- **Maximum** - No compression, original quality
- **High** - Minimal compression, 70% quality
- **Medium** - Balanced, 50% quality
- **Low** - Aggressive, 30% quality, 800px max
- **Extreme** - Maximum compression, 10% quality, 400px max

## How It Works

```swift
// 9-level compression pipeline
Original → High Quality → Medium → Low → Extreme → 
Grayscale → Ultra-small (300px) → Tiny (200px)
```

1. **Image Downsampling** - Scales large images to max dimensions
2. **JPEG Compression** - Configurable quality (10%-100%)
3. **Grayscale Conversion** - For extreme compression (optional)
4. **Iterative Optimization** - Binary search for target sizes

## Architecture

```
PDFCompressor/
├── PDFCompressor/
│   ├── PDFCompressorApp.swift      # App entry
│   ├── Models/
│   │   ├── CompressionSettings.swift
│   │   └── PDFCompressor.swift      # Core engine
│   ├── ViewModels/
│   │   └── CompressorViewModel.swift
│   └── Views/
│       ├── ContentView.swift
│       └── PDFDropDelegate.swift
├── Package.swift
└── README.md
```

## Technical Details

- **Frameworks**: PDFKit, CoreGraphics, ImageIO, SwiftUI
- **Architecture**: MVVM with async/await
- **Min System**: macOS 13.0+
- **Dependencies**: None (100% native)

## Why Native?

- **No Privacy Concerns** - Your PDFs never leave your Mac
- **Fast** - Direct framework access, no overhead
- **Reliable** - Uses battle-tested Apple frameworks
- **Small** - App size < 5MB

## Keywords

PDF compression macOS, reduce PDF file size, PDF optimizer, Swift PDF compressor, macOS PDF tool, PDF size reducer, native PDF compression, SwiftUI PDF app, compress PDF to 1MB, small PDF mac

## License

MIT License - See [LICENSE](LICENSE) file

## Contributing

Pull requests welcome. For major changes, please open an issue first.
