#!/usr/bin/env swift

import AppKit
import CoreText

enum DeviceKind {
    case iPhone69
    case iPad13

    var canvas: NSSize {
        switch self {
        case .iPhone69: return NSSize(width: 1_320, height: 2_868)
        case .iPad13: return NSSize(width: 2_064, height: 2_752)
        }
    }

    var fileLabel: String {
        switch self {
        case .iPhone69: return "iPhone_6_9"
        case .iPad13: return "iPad_13"
        }
    }
}

enum FrameMode {
    case fullScreen
    case topFocused
}

struct MarketingAsset {
    let ordinal: Int
    let device: DeviceKind
    let sourceName: String
    let slug: String
    let eyebrow: String
    let headline: String
    let subheadline: String
    let footer: String
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let accent: NSColor
    let frameMode: FrameMode
    let cropTopPixels: CGFloat
}

enum AssetError: Error, CustomStringConvertible {
    case missingImage(URL)
    case bitmapCreationFailed
    case encodingFailed(URL)

    var description: String {
        switch self {
        case .missingImage(let url): return "Missing source screenshot: \(url.path)"
        case .bitmapCreationFailed: return "Could not create RGB bitmap"
        case .encodingFailed(let url): return "Could not encode \(url.path)"
        }
    }
}

let fileManager = FileManager.default
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let repositoryURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let screenshotsURL = repositoryURL.appendingPathComponent("fastlane/screenshots/en-US")
let releaseURL = repositoryURL.appendingPathComponent("AppStoreAssets/ReleaseScreenshots/en-US")
let fontURL = repositoryURL.appendingPathComponent("NameSnap/Fonts/RubikMonoOne-Regular.ttf")

CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

let ink = NSColor(calibratedRed: 16 / 255, green: 16 / 255, blue: 24 / 255, alpha: 1)
let green = NSColor(calibratedRed: 224 / 255, green: 244 / 255, blue: 171 / 255, alpha: 1)
let sky = NSColor(calibratedRed: 107 / 255, green: 163 / 255, blue: 204 / 255, alpha: 1)
let tan = NSColor(calibratedRed: 199 / 255, green: 171 / 255, blue: 138 / 255, alpha: 1)
let yellow = NSColor(calibratedRed: 247 / 255, green: 220 / 255, blue: 96 / 255, alpha: 1)
let lavender = NSColor(calibratedRed: 163 / 255, green: 154 / 255, blue: 207 / 255, alpha: 1)
let violet = NSColor(calibratedRed: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1)
let hotPink = NSColor(calibratedRed: 1, green: 45 / 255, blue: 85 / 255, alpha: 1)
let warmWhite = NSColor(calibratedRed: 249 / 255, green: 248 / 255, blue: 244 / 255, alpha: 1)

func asset(
    _ ordinal: Int,
    _ device: DeviceKind,
    _ source: String,
    _ slug: String,
    _ eyebrow: String,
    _ headline: String,
    _ subheadline: String,
    _ footer: String,
    _ top: NSColor,
    _ bottom: NSColor,
    _ accent: NSColor,
    _ frameMode: FrameMode = .fullScreen,
    _ cropTopPixels: CGFloat = 0
) -> MarketingAsset {
    MarketingAsset(
        ordinal: ordinal,
        device: device,
        sourceName: source,
        slug: slug,
        eyebrow: eyebrow,
        headline: headline,
        subheadline: subheadline,
        footer: footer,
        backgroundTop: top,
        backgroundBottom: bottom,
        accent: accent,
        frameMode: frameMode,
        cropTopPixels: cropTopPixels
    )
}

let phoneAssets: [MarketingAsset] = [
    asset(1, .iPhone69, "05_iphone_69_celebration.png", "Celebration", "WINNER REVEAL", "MAKE EVERY WINNER\nA BIG DEAL", "300 celebration variations turn one fair pick into the main event.", "MUSIC • CONFETTI • PURE HYPE", lavender, warmWhite, yellow),
    asset(2, .iPhone69, "01_iphone_69_add_16_names.png", "Paste", "FAST SETUP", "PASTE A WHOLE\nGROUP AT ONCE", "One name per line. NameSnap numbers the pool automatically.", "CLASS • GAMES • GIVEAWAYS", green, lavender, sky),
    asset(3, .iPhone69, "02_iphone_69_names_added.png", "Quick_Pick", "QUICK PICK", "ONE TAP.\nONE FAIR PICK.", "Keep the room moving with a fast, numbered random draw.", "READY IN SECONDS", sky, green, yellow),
    asset(4, .iPhone69, "04_iphone_69_wheel_ready.png", "Spin_Wheel", "SPIN WHEEL", "SPIN IT LIKE\nA GAME SHOW", "Swipe anywhere on the wheel or use the big spin control.", "EVERY NAME STAYS NUMBERED", lavender, sky, tan),
    asset(5, .iPhone69, "06_iphone_69_history.png", "No_Repeats", "FAIR BY DESIGN", "NO REPEATS.\nNO GUESSING.", "Winners sit out while recent picks stay easy to verify.", "CLEAR HISTORY AT A GLANCE", green, warmWhite, hotPink),
    asset(6, .iPhone69, "07_iphone_69_reset_confirm.png", "Reset", "FULL CONTROL", "RESET PICKS.\nKEEP THE LIST.", "Start a fresh round without typing the same names again.", "NO ACCOUNT • LIST STAYS LOCAL", warmWhite, lavender, yellow)
]

let tabletAssets: [MarketingAsset] = [
    asset(1, .iPad13, "12_ipad_13_celebration.png", "Celebration", "WINNER REVEAL", "MAKE EVERY WINNER\nA BIG DEAL", "A full-screen celebration built for classrooms, streams, and big groups.", "MUSIC • CONFETTI • PURE HYPE", lavender, warmWhite, yellow),
    asset(2, .iPad13, "08_ipad_13_add_16_names.png", "Paste", "FAST SETUP", "PASTE A WHOLE\nGROUP AT ONCE", "One name per line. NameSnap numbers the pool automatically.", "CLASS • GAMES • GIVEAWAYS", green, lavender, sky, .topFocused),
    asset(3, .iPad13, "09_ipad_13_names_added.png", "Quick_Pick", "QUICK PICK", "ONE TAP.\nONE FAIR PICK.", "Use the large iPad canvas to run a draw everyone can follow.", "READY IN SECONDS", sky, green, yellow, .topFocused),
    asset(4, .iPad13, "11_ipad_13_wheel_ready.png", "Spin_Wheel", "SPIN WHEEL", "SPIN IT LIKE\nA GAME SHOW", "The centered numbered wheel stays easy to read across the room.", "EVERY NAME STAYS NUMBERED", lavender, sky, tan, .topFocused),
    asset(5, .iPad13, "13_ipad_13_history.png", "No_Repeats", "FAIR BY DESIGN", "NO REPEATS.\nNO GUESSING.", "Winners sit out while recent picks stay easy to verify.", "CLEAR HISTORY AT A GLANCE", green, warmWhite, hotPink, .topFocused),
    asset(6, .iPad13, "14_ipad_13_reset_confirm.png", "Reset", "FULL CONTROL", "RESET PICKS.\nKEEP THE LIST.", "Start a fresh round without typing the same names again.", "NO ACCOUNT • LIST STAYS LOCAL", warmWhite, lavender, yellow, .topFocused)
]

let assets = phoneAssets + tabletAssets

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvasHeight: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func fittedFont(named name: String, maxSize: CGFloat, minSize: CGFloat, text: String, width: CGFloat) -> NSFont {
    var size = maxSize
    let longestLine = text.components(separatedBy: "\n").max(by: { $0.count < $1.count }) ?? text
    while size > minSize {
        let font = NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .black)
        let measured = (longestLine as NSString).size(withAttributes: [.font: font]).width
        if measured <= width { return font }
        size -= 2
    }
    return NSFont(name: name, size: minSize) ?? .systemFont(ofSize: minSize, weight: .black)
}

func drawCenteredText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    lineSpacing: CGFloat = 0,
    tracking: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = lineSpacing
    let attributed = NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: tracking
        ]
    )
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

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let sourceImage = bitmap.cgImage else {
        throw AssetError.encodingFailed(url)
    }
    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let rgbContext = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw AssetError.bitmapCreationFailed
    }
    rgbContext.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let flattenedImage = rgbContext.makeImage() else {
        throw AssetError.encodingFailed(url)
    }
    let flattenedBitmap = NSBitmapImageRep(cgImage: flattenedImage)
    guard let data = flattenedBitmap.representation(using: .png, properties: [:]) else {
        throw AssetError.encodingFailed(url)
    }
    try data.write(to: url, options: .atomic)
}

func drawRoundedPanel(_ rect: NSRect, radius: CGFloat, fill: NSColor, strokeWidth: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    ink.setStroke()
    path.lineWidth = strokeWidth
    path.stroke()
}

func croppingTopPixels(_ image: NSImage, pixels: CGFloat) -> NSImage {
    guard pixels > 0,
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return image
    }
    let safePixels = min(max(Int(pixels.rounded()), 0), max(cgImage.height - 1, 0))
    guard safePixels > 0,
          let cropped = cgImage.cropping(
            to: CGRect(x: 0, y: safePixels, width: cgImage.width, height: cgImage.height - safePixels)
          ) else {
        return image
    }
    return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
}

func drawScreen(_ screenshot: NSImage, inside frameRect: NSRect, radius: CGFloat, mode: FrameMode, accent: NSColor) {
    let shadowRect = frameRect.offsetBy(dx: 18, dy: -22)
    drawRoundedPanel(shadowRect, radius: radius, fill: violet, strokeWidth: 7)
    drawRoundedPanel(frameRect, radius: radius, fill: warmWhite, strokeWidth: 8)

    let inset = frameRect.insetBy(dx: 15, dy: 15)
    let clip = NSBezierPath(roundedRect: inset, xRadius: radius - 10, yRadius: radius - 10)
    NSGraphicsContext.saveGraphicsState()
    clip.addClip()

    switch mode {
    case .fullScreen:
        screenshot.draw(in: inset, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    case .topFocused:
        let scale = max(inset.width / screenshot.size.width, inset.height / screenshot.size.height)
        let drawSize = NSSize(width: screenshot.size.width * scale, height: screenshot.size.height * scale)
        let drawRect = NSRect(
            x: inset.midX - drawSize.width / 2,
            y: inset.maxY - drawSize.height,
            width: drawSize.width,
            height: drawSize.height
        )
        screenshot.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
    NSGraphicsContext.restoreGraphicsState()

    let tabWidth = min(frameRect.width * 0.28, 330)
    let tabRect = NSRect(x: frameRect.minX + 34, y: frameRect.maxY - 40, width: tabWidth, height: 54)
    drawRoundedPanel(tabRect, radius: 27, fill: accent, strokeWidth: 4)
}

func render(_ asset: MarketingAsset) throws {
    let sourceURL = screenshotsURL.appendingPathComponent(asset.sourceName)
    guard let originalScreenshot = NSImage(contentsOf: sourceURL) else {
        throw AssetError.missingImage(sourceURL)
    }
    let screenshot = croppingTopPixels(originalScreenshot, pixels: asset.cropTopPixels)

    let canvas = asset.device.canvas
    let isTablet = asset.device == .iPad13
    let bitmap = try makeBitmap(size: canvas)
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw AssetError.bitmapCreationFailed
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    NSGradient(starting: asset.backgroundTop, ending: asset.backgroundBottom)?.draw(in: NSRect(origin: .zero, size: canvas), angle: -90)

    asset.accent.withAlphaComponent(0.24).setFill()
    NSBezierPath(ovalIn: NSRect(x: -canvas.width * 0.18, y: canvas.height * 0.56, width: canvas.width * 0.76, height: canvas.width * 0.76)).fill()
    sky.withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: canvas.width * 0.55, y: canvas.height * 0.71, width: canvas.width * 0.56, height: canvas.width * 0.56)).fill()

    let outerInset: CGFloat = isTablet ? 92 : 58
    let eyebrowHeight: CGFloat = isTablet ? 76 : 66
    let eyebrowWidth: CGFloat = isTablet ? 500 : 390
    let eyebrowTop: CGFloat = isTablet ? 54 : 48
    let eyebrowRect = topRect(
        x: (canvas.width - eyebrowWidth) / 2,
        y: eyebrowTop,
        width: eyebrowWidth,
        height: eyebrowHeight,
        canvasHeight: canvas.height
    )
    drawRoundedPanel(eyebrowRect, radius: eyebrowHeight / 2, fill: asset.accent, strokeWidth: isTablet ? 5 : 4)
    drawCenteredText(
        asset.eyebrow,
        in: eyebrowRect.insetBy(dx: 20, dy: 8),
        font: fittedFont(named: "RubikMonoOne-Regular", maxSize: isTablet ? 27 : 22, minSize: 17, text: asset.eyebrow, width: eyebrowRect.width - 40),
        color: ink,
        tracking: 1.4
    )

    let headlineTop: CGFloat = isTablet ? 145 : 135
    let headlineHeight: CGFloat = isTablet ? 240 : 260
    let headlineFont = fittedFont(
        named: "RubikMonoOne-Regular",
        maxSize: isTablet ? 82 : 82,
        minSize: isTablet ? 58 : 56,
        text: asset.headline,
        width: canvas.width - outerInset * 2
    )
    drawCenteredText(
        asset.headline,
        in: topRect(x: outerInset, y: headlineTop, width: canvas.width - outerInset * 2, height: headlineHeight, canvasHeight: canvas.height),
        font: headlineFont,
        color: ink,
        lineSpacing: isTablet ? 10 : 12
    )

    let subTop: CGFloat = isTablet ? 380 : 390
    let subHeight: CGFloat = isTablet ? 90 : 105
    drawCenteredText(
        asset.subheadline,
        in: topRect(x: outerInset * 1.25, y: subTop, width: canvas.width - outerInset * 2.5, height: subHeight, canvasHeight: canvas.height),
        font: .systemFont(ofSize: isTablet ? 30 : 30, weight: .bold),
        color: ink.withAlphaComponent(0.78),
        lineSpacing: 4
    )

    let frameTop: CGFloat = isTablet ? 505 : 530
    let footerHeight: CGFloat = isTablet ? 118 : 126
    let footerBottom: CGFloat = isTablet ? 46 : 42
    let maxFrameHeight = canvas.height - frameTop - footerHeight - footerBottom - 34
    let frameRect: NSRect

    if isTablet && asset.frameMode == .topFocused {
        let frameWidth = canvas.width - 2 * 112
        frameRect = topRect(
            x: 112,
            y: frameTop,
            width: frameWidth,
            height: maxFrameHeight,
            canvasHeight: canvas.height
        )
    } else {
        let maxFrameWidth = canvas.width - 2 * (isTablet ? 230 : 112)
        let sourceAspect = screenshot.size.width / screenshot.size.height
        let frameWidth = min(maxFrameWidth, maxFrameHeight * sourceAspect)
        let frameHeight = frameWidth / sourceAspect
        frameRect = topRect(
            x: (canvas.width - frameWidth) / 2,
            y: frameTop,
            width: frameWidth,
            height: frameHeight,
            canvasHeight: canvas.height
        )
    }

    drawScreen(
        screenshot,
        inside: frameRect,
        radius: isTablet ? 54 : 66,
        mode: asset.frameMode,
        accent: asset.accent
    )

    let footerRect = topRect(
        x: isTablet ? 250 : 110,
        y: canvas.height - footerHeight - footerBottom,
        width: canvas.width - (isTablet ? 500 : 220),
        height: footerHeight,
        canvasHeight: canvas.height
    )
    drawRoundedPanel(footerRect.offsetBy(dx: 10, dy: -10), radius: footerHeight / 2, fill: violet, strokeWidth: 5)
    drawRoundedPanel(footerRect, radius: footerHeight / 2, fill: warmWhite, strokeWidth: 5)
    drawCenteredText(
        asset.footer,
        in: footerRect.insetBy(dx: 28, dy: 12),
        font: fittedFont(named: "RubikMonoOne-Regular", maxSize: isTablet ? 28 : 23, minSize: 15, text: asset.footer, width: footerRect.width - 56),
        color: ink,
        tracking: 1
    )

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let outputName = String(format: "%02d_NameSnap_%@_%@.png", asset.ordinal, asset.device.fileLabel, asset.slug)
    let outputURL = releaseURL.appendingPathComponent(outputName)
    try writePNG(bitmap, to: outputURL)
    print(outputURL.path)
}

do {
    try fileManager.createDirectory(at: releaseURL, withIntermediateDirectories: true)

    // This directory is an upload-ready generated surface. Remove only the
    // NameSnap PNGs owned by this generator so stale paywall-era assets cannot
    // accidentally ship alongside the refreshed set.
    for fileURL in try fileManager.contentsOfDirectory(at: releaseURL, includingPropertiesForKeys: nil) {
        if fileURL.pathExtension.lowercased() == "png" && fileURL.lastPathComponent.hasPrefix("0") {
            try fileManager.removeItem(at: fileURL)
        }
    }

    for item in assets {
        try render(item)
    }
} catch {
    fputs("Asset generation failed: \(error)\n", stderr)
    exit(1)
}
