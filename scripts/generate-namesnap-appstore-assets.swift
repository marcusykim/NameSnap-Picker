#!/usr/bin/env swift

import AppKit
import CoreText

struct MarketingAsset {
    let source: URL
    let output: URL
    let rawOutput: URL
    let canvasSize: NSSize
    let headline: String
    let footer: String
    let isJPEGRaw: Bool
}

enum AssetError: Error {
    case missingImage(URL)
    case bitmapCreationFailed
    case encodingFailed(URL)
}

let fileManager = FileManager.default
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let repositoryURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let screenshotsURL = repositoryURL.appendingPathComponent("fastlane/screenshots/en-US")
let assetsURL = repositoryURL.appendingPathComponent("AppStoreAssets/Final_Assets_2026-02-23")
let iPadAssetsURL = assetsURL.appendingPathComponent("Screenshots_iPad_13in_2048x2732")
let fontURL = repositoryURL.appendingPathComponent("NameSnap/Fonts/RubikMonoOne-Regular.ttf")

CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

let phoneCanvas = NSSize(width: 1_284, height: 2_778)
let tabletCanvas = NSSize(width: 2_048, height: 2_732)

let assets: [MarketingAsset] = [
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("05_iphone_69_winner.png"),
        output: assetsURL.appendingPathComponent("NameSnap-Hero-1284x2778.png"),
        rawOutput: assetsURL.appendingPathComponent("NameSnap-Hero-raw.png"),
        canvasSize: phoneCanvas,
        headline: "PICK A WINNER\nIN SECONDS",
        footer: "CLASS • GAMES • LIVESTREAMS",
        isJPEGRaw: false
    ),
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("03_iphone_69_classic_ready.png"),
        output: assetsURL.appendingPathComponent("NameSnap-Details-1284x2778.png"),
        rawOutput: assetsURL.appendingPathComponent("NameSnap-Details-raw.png"),
        canvasSize: phoneCanvas,
        headline: "EVERY NAME.\nONE FAIR POOL.",
        footer: "PASTE • PICK • REPEAT",
        isJPEGRaw: false
    ),
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("07_iphone_69_upgrade.png"),
        output: assetsURL.appendingPathComponent("NameSnap-Privacy-1284x2778.png"),
        rawOutput: assetsURL.appendingPathComponent("NameSnap-Privacy-raw.png"),
        canvasSize: phoneCanvas,
        headline: "NO ACCOUNT\nREQUIRED",
        footer: "PRIVATE • LOCAL • SIMPLE",
        isJPEGRaw: false
    ),
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("09_ipad_13_names_added.png"),
        output: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Hero-2048x2732.png"),
        rawOutput: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Hero-raw.jpg"),
        canvasSize: tabletCanvas,
        headline: "ADD THE WHOLE POOL\nIN ONE PASTE",
        footer: "FAST SETUP • FAIR PICKS",
        isJPEGRaw: true
    ),
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("10_ipad_13_classic_ready.png"),
        output: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Details-2048x2732.png"),
        rawOutput: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Details-raw.jpg"),
        canvasSize: tabletCanvas,
        headline: "16 NAMES.\nREADY TO SPIN.",
        footer: "CLASS • GAMES • LIVESTREAMS",
        isJPEGRaw: true
    ),
    MarketingAsset(
        source: screenshotsURL.appendingPathComponent("11_ipad_13_upgrade.png"),
        output: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Privacy-2048x2732.png"),
        rawOutput: iPadAssetsURL.appendingPathComponent("NameSnap-iPad-Privacy-raw.jpg"),
        canvasSize: tabletCanvas,
        headline: "NO ACCOUNT.\nNO TRACKING.",
        footer: "YOUR LIST STAYS YOURS",
        isJPEGRaw: true
    )
]

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvasHeight: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func fittedFont(named name: String, maxSize: CGFloat, minSize: CGFloat, text: String, width: CGFloat) -> NSFont {
    var size = maxSize
    while size > minSize {
        let font = NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .black)
        let measured = (text as NSString).size(withAttributes: [.font: font]).width
        if measured <= width { return font }
        size -= 2
    }
    return NSFont(name: name, size: minSize) ?? .systemFont(ofSize: minSize, weight: .black)
}

func drawCenteredText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, lineSpacing: CGFloat) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = lineSpacing
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let measured = attributed.boundingRect(
        with: NSSize(width: rect.width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    attributed.draw(in: NSRect(x: rect.minX, y: rect.midY - measured.height / 2, width: rect.width, height: measured.height))
}

func makeBitmap(size: NSSize) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw AssetError.bitmapCreationFailed
    }
    bitmap.size = size
    return bitmap
}

func write(_ bitmap: NSBitmapImageRep, to url: URL, type: NSBitmapImageRep.FileType, properties: [NSBitmapImageRep.PropertyKey: Any] = [:]) throws {
    guard let data = bitmap.representation(using: type, properties: properties) else {
        throw AssetError.encodingFailed(url)
    }
    try data.write(to: url, options: .atomic)
}

func writeRawImage(_ image: NSImage, asset: MarketingAsset) throws {
    guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw AssetError.encodingFailed(asset.rawOutput)
    }
    let bitmap = NSBitmapImageRep(cgImage: source)
    if asset.isJPEGRaw {
        try write(bitmap, to: asset.rawOutput, type: .jpeg, properties: [.compressionFactor: 0.94])
    } else {
        try write(bitmap, to: asset.rawOutput, type: .png)
    }
}

func render(_ asset: MarketingAsset) throws {
    guard let screenshot = NSImage(contentsOf: asset.source) else {
        throw AssetError.missingImage(asset.source)
    }
    try writeRawImage(screenshot, asset: asset)

    let canvas = asset.canvasSize
    let bitmap = try makeBitmap(size: canvas)
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw AssetError.bitmapCreationFailed
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let background = NSColor(calibratedRed: 0.87, green: 0.98, blue: 0.64, alpha: 1)
    let brandBlue = NSColor(calibratedRed: 0.35, green: 0.63, blue: 0.82, alpha: 1)
    let sand = NSColor(calibratedRed: 0.78, green: 0.68, blue: 0.52, alpha: 0.45)
    background.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()

    let isTablet = canvas.width > 1_500
    let haloSize = isTablet ? canvas.width * 0.70 : canvas.width * 0.86
    let haloRect = NSRect(
        x: (canvas.width - haloSize) / 2,
        y: canvas.height * 0.27,
        width: haloSize,
        height: haloSize
    )
    sand.setFill()
    NSBezierPath(ovalIn: haloRect).fill()

    let titleHeight: CGFloat = isTablet ? 330 : 360
    let titleTop: CGFloat = isTablet ? 55 : 65
    let titleInset: CGFloat = isTablet ? 130 : 72
    let titleFont = fittedFont(
        named: "RubikMonoOne-Regular",
        maxSize: isTablet ? 108 : 96,
        minSize: isTablet ? 72 : 66,
        text: asset.headline.components(separatedBy: "\n").max(by: { $0.count < $1.count }) ?? asset.headline,
        width: canvas.width - (titleInset * 2)
    )
    drawCenteredText(
        asset.headline,
        in: topRect(x: titleInset, y: titleTop, width: canvas.width - titleInset * 2, height: titleHeight, canvasHeight: canvas.height),
        font: titleFont,
        color: brandBlue,
        lineSpacing: isTablet ? 20 : 14
    )

    let frameTop: CGFloat = isTablet ? 430 : 445
    let frameBottom: CGFloat = isTablet ? 225 : 245
    let frameHeight = canvas.height - frameTop - frameBottom
    let sourceAspect = screenshot.size.width / screenshot.size.height
    let maxFrameWidth = canvas.width - (isTablet ? 130 : 150)
    let frameWidth = min(maxFrameWidth, frameHeight * sourceAspect)
    let frameRect = topRect(
        x: (canvas.width - frameWidth) / 2,
        y: frameTop,
        width: frameWidth,
        height: frameHeight,
        canvasHeight: canvas.height
    )
    let frameRadius: CGFloat = isTablet ? 46 : 58

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = isTablet ? 32 : 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor.black.setFill()
    NSBezierPath(roundedRect: frameRect.insetBy(dx: -12, dy: -12), xRadius: frameRadius + 8, yRadius: frameRadius + 8).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: frameRect, xRadius: frameRadius, yRadius: frameRadius).addClip()
    screenshot.draw(in: frameRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()

    let footerFont = fittedFont(
        named: "RubikMonoOne-Regular",
        maxSize: isTablet ? 48 : 42,
        minSize: isTablet ? 34 : 28,
        text: asset.footer,
        width: canvas.width - (isTablet ? 120 : 80)
    )
    drawCenteredText(
        asset.footer,
        in: topRect(x: 40, y: canvas.height - frameBottom + 52, width: canvas.width - 80, height: frameBottom - 70, canvasHeight: canvas.height),
        font: footerFont,
        color: brandBlue,
        lineSpacing: 0
    )

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    try write(bitmap, to: asset.output, type: .png)
    print(asset.output.path)
}

do {
    try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: iPadAssetsURL, withIntermediateDirectories: true)
    for asset in assets {
        try render(asset)
    }
} catch {
    fputs("Asset generation failed: \(error)\n", stderr)
    exit(1)
}
