import SwiftUI
import Combine
import UIKit
import AudioToolbox
import AVFoundation
import StoreKit
import ImageIO

struct NameEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var drawNumber: Int
    var name: String
    var isIncluded: Bool

    init(id: UUID = UUID(), drawNumber: Int, name: String, isIncluded: Bool = true) {
        self.id = id
        self.drawNumber = drawNumber
        self.name = name
        self.isIncluded = isIncluded
    }
}

struct WinnerRecord: Identifiable, Hashable {
    let id = UUID()
    let drawNumber: Int
    let name: String

    var displayText: String { "\(drawNumber). \(name)" }
}

private enum WinnerCelebrationHero: String, CaseIterable {
    case dancer
    case guitarist
    case dynamite
    case hypeMascot = "hype-mascot"
    case pixelBomb = "pixel-bomb"
    case breakdancer
    case dj
    case drummer
    case skater
    case trumpet
    case saxophonist
    case cheerCaptain = "cheer-captain"
    case magician
    case skateboarder
    case soccerStriker = "soccer-striker"
    case basketballDunker = "basketball-dunker"
    case astronaut
    case robot
    case superhero
    case operaSinger = "opera-singer"
    case punkVocalist = "punk-vocalist"
    case keytarist
    case discoDancer = "disco-dancer"
    case conductor
    case juggler
    case pirateCaptain = "pirate-captain"
    case knight
    case rocketScientist = "rocket-scientist"
    case gamer
    case rodeoStar = "rodeo-star"

    var label: String {
        switch self {
        case .dancer: return "Victory dance"
        case .guitarist: return "Face-melting solo"
        case .dynamite: return "Celebration blast"
        case .hypeMascot: return "Maximum hype"
        case .pixelBomb: return "Bonus explosion"
        case .breakdancer: return "Breakdance victory"
        case .dj: return "Dance-floor takeover"
        case .drummer: return "Thunderous drum solo"
        case .skater: return "Victory on wheels"
        case .trumpet: return "Stadium fanfare"
        case .saxophonist: return "Saxophone victory solo"
        case .cheerCaptain: return "Jump-and-cheer finale"
        case .magician: return "Confetti magic"
        case .skateboarder: return "Kickflip victory"
        case .soccerStriker: return "Goal celebration"
        case .basketballDunker: return "Victory dunk"
        case .astronaut: return "Zero-gravity victory"
        case .robot: return "Robot victory dance"
        case .superhero: return "Hero landing"
        case .operaSinger: return "Final victory note"
        case .punkVocalist: return "Punk encore"
        case .keytarist: return "Keytar takeover"
        case .discoDancer: return "Disco victory"
        case .conductor: return "Triumphant finale"
        case .juggler: return "Victory juggling act"
        case .pirateCaptain: return "Treasure champion"
        case .knight: return "Shield-raised champion"
        case .rocketScientist: return "Rocket-powered genius"
        case .gamer: return "Game-winning jump"
        case .rodeoStar: return "Rodeo victory"
        }
    }
}

private struct WinnerCelebration: Identifiable {
    static let variationCount = 300
    static let audioNames = [
        "techno_upbeat_01", "techno_upbeat_02", "techno_upbeat_03", "techno_upbeat_04",
        "techno_upbeat_alt_01", "techno_upbeat_alt_02", "techno_upbeat_alt_03", "techno_upbeat_alt_04",
        "techno_upbeat_alt_05", "techno_upbeat_alt_06", "celebration_airhorn", "celebration_metal",
        "celebration_crowd", "celebration_fanfare", "celebration_fireworks", "celebration_explosion"
    ]
    static let headlines = ["THE PICK IS IN", "ABSOLUTE LEGEND", "WINNER ENERGY", "MAKE SOME NOISE", "MAIN CHARACTER MOMENT"]

    let id = UUID()
    let variation: Int
    let drawNumber: Int
    let winnerName: String

    var hero: WinnerCelebrationHero {
        WinnerCelebrationHero.allCases[variation % WinnerCelebrationHero.allCases.count]
    }
    var palette: Int { (variation / WinnerCelebrationHero.allCases.count) % 5 }
    var entersFromRight: Bool { variation < Self.variationCount / 2 }
    var audioName: String { Self.audioNames[variation % Self.audioNames.count] }
    var headline: String { Self.headlines[palette] }

    init(displayText: String, variation: Int = Int.random(in: 0..<WinnerCelebration.variationCount)) {
        let parts = displayText.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        drawNumber = Int(parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 1
        winnerName = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : displayText
        self.variation = ((variation % Self.variationCount) + Self.variationCount) % Self.variationCount
    }
}

enum NSTheme {
    static let ink = Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255)
    static let bg = Color(red: 224 / 255, green: 244 / 255, blue: 171 / 255)
    static let skyBlue = Color(red: 107 / 255, green: 163 / 255, blue: 204 / 255)
    static let tan = Color(red: 199 / 255, green: 171 / 255, blue: 138 / 255)
    static let card = Color(red: 242 / 255, green: 244 / 255, blue: 250 / 255)
    static let yellow = Color(red: 247 / 255, green: 220 / 255, blue: 96 / 255)
    static let lavender = Color(red: 163 / 255, green: 154 / 255, blue: 207 / 255)
    static let violet = Color(red: 88 / 255, green: 86 / 255, blue: 214 / 255)
    static let hotPink = Color(red: 1, green: 45 / 255, blue: 85 / 255)
    static let warmWhite = Color(red: 249 / 255, green: 248 / 255, blue: 244 / 255)

    static let pageGradient = LinearGradient(
        colors: [
            bg,
            Color(red: 218 / 255, green: 214 / 255, blue: 244 / 255),
            Color(red: 244 / 255, green: 246 / 255, blue: 252 / 255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [lavender.opacity(0.72), Color.white.opacity(0.96), card],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fieldGradient = LinearGradient(
        colors: [Color.white, Color(red: 239 / 255, green: 239 / 255, blue: 252 / 255)],
        startPoint: .top,
        endPoint: .bottomTrailing
    )
}

private struct NameSnapActionModalSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NSTheme.panelGradient)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(NSTheme.ink, lineWidth: 3)
            )
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(NSTheme.violet)
                    .offset(x: 7, y: 9)
            }
            .shadow(color: NSTheme.ink.opacity(0.2), radius: 20, x: 0, y: 16)
    }
}

private struct NameSnapPanelSurface: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(NSTheme.panelGradient)
            .clipShape(shape)
            .overlay(shape.stroke(NSTheme.ink, lineWidth: 2.5))
            .background {
                shape
                    .fill(NSTheme.violet)
                    .offset(x: 6, y: 7)
            }
            .shadow(color: NSTheme.ink.opacity(0.14), radius: 12, x: 0, y: 10)
    }
}

private enum NameSnapButtonTone {
    case primary
    case secondary
    case destructive
    case warm

    var fill: LinearGradient {
        switch self {
        case .primary:
            return LinearGradient(colors: [NSTheme.lavender, NSTheme.skyBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .secondary:
            return LinearGradient(colors: [Color.white, NSTheme.card], startPoint: .top, endPoint: .bottomTrailing)
        case .destructive:
            return LinearGradient(colors: [NSTheme.hotPink, Color(red: 1, green: 112 / 255, blue: 96 / 255)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            return LinearGradient(colors: [NSTheme.yellow, NSTheme.tan], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct NameSnapButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let tone: NameSnapButtonTone

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(NSTheme.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(tone.fill)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(NSTheme.ink, lineWidth: 2.5))
            .shadow(color: NSTheme.ink, radius: 0, x: 0, y: configuration.isPressed ? 1 : 5)
            .offset(y: configuration.isPressed ? 4 : 0)
            .opacity(isEnabled ? 1 : 0.42)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct NameSnapModeButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(celebrationTitleFont(size: 10))
            .foregroundStyle(NSTheme.ink)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(isSelected ? NameSnapButtonTone.warm.fill : NameSnapButtonTone.secondary.fill)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(NSTheme.ink, lineWidth: 2))
            .shadow(color: isSelected ? NSTheme.violet : Color.clear, radius: 0, x: 0, y: isSelected ? 4 : 0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private extension View {
    func nameSnapActionModalSurface() -> some View {
        modifier(NameSnapActionModalSurface())
    }

    func nameSnapPanelSurface(cornerRadius: CGFloat = 24) -> some View {
        modifier(NameSnapPanelSurface(cornerRadius: cornerRadius))
    }
}

private func celebrationTitleFont(size: CGFloat) -> Font {
    if UIFont(name: "RubikMonoOne-Regular", size: size) != nil {
        return .custom("RubikMonoOne-Regular", size: size)
    }
    if UIFont(name: "Rubik Mono One", size: size) != nil {
        return .custom("Rubik Mono One", size: size)
    }
    return .system(size: size, weight: .black, design: .rounded)
}

private struct AnimatedGIFImage: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.image = Self.animatedImage(named: resourceName)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    private static func animatedImage(named resourceName: String) -> UIImage? {
        let rootURL = Bundle.main.url(forResource: resourceName, withExtension: "gif")
        let nestedURL = Bundle.main.url(forResource: resourceName, withExtension: "gif", subdirectory: "Celebrations")
        guard let url = rootURL ?? nestedURL,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0
        for index in 0..<CGImageSourceGetCount(source) {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let unclampedDelay = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? Double
            let delay = unclampedDelay ?? (gifProperties?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.08
            frames.append(UIImage(cgImage: frame))
            totalDuration += max(delay, 0.035)
        }

        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: max(totalDuration, 0.1))
    }
}

private struct WinnerCelebrationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let celebration: WinnerCelebration
    let onDismiss: () -> Void
    let onReset: () -> Void

    @State private var animateHero = false
    @State private var animateConfetti = false
    @State private var animateCard = false

    private var palette: [Color] {
        switch celebration.palette {
        case 1: return [NSTheme.bg, NSTheme.skyBlue, NSTheme.yellow]
        case 2: return [Color(red: 1, green: 45 / 255, blue: 85 / 255), NSTheme.yellow, NSTheme.skyBlue]
        case 3: return [NSTheme.skyBlue, Color(red: 1, green: 45 / 255, blue: 85 / 255), NSTheme.bg]
        case 4: return [NSTheme.tan, Color(red: 88 / 255, green: 86 / 255, blue: 214 / 255), NSTheme.yellow]
        default: return [NSTheme.yellow, Color(red: 88 / 255, green: 86 / 255, blue: 214 / 255), Color(red: 1, green: 45 / 255, blue: 85 / 255)]
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 700
            let cardWidth = compact ? proxy.size.width - 24 : min(proxy.size.width * 0.72, 760)
            let cardHeight = compact ? proxy.size.height - 24 : min(proxy.size.height - 56, 650)
            let heroWidth = compact ? min(proxy.size.width * 0.5, 220) : min(proxy.size.width * 0.36, 520)

            ZStack {
                Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255)
                    .overlay(
                        RadialGradient(
                            colors: [palette[0].opacity(0.46), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: max(proxy.size.width, proxy.size.height) * 0.62
                        )
                    )
                    .ignoresSafeArea()

                if !reduceMotion {
                    AnimatedGIFImage(resourceName: "confetti-burst")
                        .frame(width: min(proxy.size.width * 0.62, 430), height: min(proxy.size.width * 0.62, 430))
                        .rotationEffect(.degrees(-14))
                        .offset(x: -proxy.size.width * 0.34, y: -proxy.size.height * 0.28)
                        .opacity(0.9)

                    confettiRain(in: proxy.size)
                }

                celebrationHero(compact: compact, width: heroWidth)
                    .offset(
                        x: compact ? 0 : (celebration.entersFromRight ? proxy.size.width * 0.37 : -proxy.size.width * 0.37),
                        y: compact ? -proxy.size.height * 0.31 : 0
                    )
                    // On iPhone the hero occupies the reserved header space inside the card.
                    // On iPad it becomes a background flourish so it can never cover a long
                    // winner name or either action button.
                    .zIndex(compact ? 4 : 2)

                celebrationCard(compact: compact)
                    .frame(width: max(cardWidth, 0), height: max(cardHeight, 0))
                    .scaleEffect(reduceMotion ? 1 : (animateCard ? 1 : 0.74))
                    .rotationEffect(.degrees(reduceMotion ? 0 : (animateCard ? 0 : -3)))
                    .opacity(reduceMotion ? 1 : (animateCard ? 1 : 0))
                    .zIndex(3)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            if reduceMotion {
                animateHero = true
                animateCard = true
                return
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.68)) { animateCard = true }
            withAnimation(.spring(response: 0.82, dampingFraction: 0.58).delay(0.08)) { animateHero = true }
            animateConfetti = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Winner celebration. Number \(celebration.drawNumber), \(celebration.winnerName)")
    }

    @ViewBuilder
    private func celebrationHero(compact: Bool, width: CGFloat) -> some View {
        Group {
            if celebration.hero == .pixelBomb {
                AnimatedGIFImage(resourceName: celebration.hero.rawValue)
            } else if let image = rasterHeroImage(named: celebration.hero.rawValue) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("party_popper_emoji")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: celebration.hero == .pixelBomb ? width * 0.7 : width, height: compact ? width : width * 1.08)
        .shadow(color: .black.opacity(0.34), radius: 24, x: 0, y: 18)
        .scaleEffect(reduceMotion ? 0.78 : (animateHero ? 1 : 0.45))
        .rotationEffect(.degrees(reduceMotion ? 0 : (animateHero ? (celebration.entersFromRight ? 3 : -3) : (celebration.entersFromRight ? 24 : -24))))
        .offset(x: reduceMotion ? 0 : (animateHero ? 0 : (celebration.entersFromRight ? width * 1.8 : -width * 1.8)))
        .opacity(reduceMotion ? 0.36 : (animateHero ? 1 : 0))
    }

    private func rasterHeroImage(named name: String) -> UIImage? {
        if let bundled = UIImage(named: name) { return bundled }
        let rootURL = Bundle.main.url(forResource: name, withExtension: "png")
        let nestedURL = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Celebrations")
        guard let url = rootURL ?? nestedURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func celebrationCard(compact: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: compact ? 270 : 16)

                    Text(celebration.headline)
                        .font(celebrationTitleFont(size: compact ? 12 : 17))
                        .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255))
                        .tracking(compact ? 1.1 : 1.8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, compact ? 14 : 20)
                        .padding(.vertical, compact ? 7 : 9)
                        .background(palette[0])
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: 2))

                    Text("CELEBRATION \(celebration.variation + 1) / \(WinnerCelebration.variationCount) · \(celebration.hero.label.uppercased())")
                        .font(.system(size: compact ? 7 : 9, weight: .black))
                        .foregroundStyle(Color(red: 96 / 255, green: 117 / 255, blue: 139 / 255))
                        .tracking(1.1)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 12)

                    Text("\(celebration.drawNumber)")
                        .font(celebrationTitleFont(size: compact ? 38 : 57))
                        .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255))
                        .frame(width: compact ? 84 : 124, height: compact ? 84 : 124)
                        .background(palette[0])
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: compact ? 3 : 4))
                        .shadow(color: palette[2], radius: 0, x: compact ? 5 : 8, y: compact ? 6 : 9)
                        .rotationEffect(.degrees(-4))
                        .padding(.top, compact ? 15 : 24)

                    Text(celebration.winnerName)
                        .font(celebrationTitleFont(size: compact ? 39 : 62))
                        .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.55)
                        .lineLimit(3)
                        .padding(.top, compact ? 18 : 26)
                        .padding(.horizontal, 8)

                    Text("Winner #\(celebration.drawNumber) from the numbered pool. Make some noise!")
                        .font(.system(size: compact ? 13 : 16, weight: .bold))
                        .foregroundStyle(Color(red: 69 / 255, green: 93 / 255, blue: 115 / 255))
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 10)

                    HStack(spacing: 10) {
                        Button("Keep Going", action: onDismiss)
                            .buttonStyle(.plain)
                            .font(celebrationTitleFont(size: compact ? 9 : 11))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(palette[0])
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: 2))
                            .shadow(color: Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), radius: 0, x: 4, y: 5)

                        Button("Reset Picks", action: onReset)
                            .buttonStyle(.plain)
                            .font(celebrationTitleFont(size: compact ? 8 : 10))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(.white.opacity(0.92))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: 2))
                    }
                    .padding(.top, compact ? 22 : 30)
                    .padding(.horizontal, compact ? 2 : 24)
                    .padding(.bottom, compact ? 22 : 28)
                }
                .padding(.horizontal, compact ? 18 : 40)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.94))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(14)
            .accessibilityLabel("Close winner celebration")
        }
        .background(
            RadialGradient(
                colors: [palette[0].opacity(0.32), Color(red: 247 / 255, green: 248 / 255, blue: 252 / 255).opacity(0.96)],
                center: .top,
                startRadius: 10,
                endRadius: 500
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: compact ? 28 : 44, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: compact ? 28 : 44, style: .continuous).stroke(Color(red: 16 / 255, green: 16 / 255, blue: 24 / 255), lineWidth: compact ? 3 : 4))
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 28 : 44, style: .continuous)
                    .fill(Color.black.opacity(0.32))
                    .blur(radius: 26)
                    .offset(y: 26)
                RoundedRectangle(cornerRadius: compact ? 28 : 44, style: .continuous)
                    .fill(palette[1])
                    .offset(x: compact ? 7 : 12, y: compact ? 8 : 14)
            }
        }
    }

    private func confettiRain(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<72, id: \.self) { index in
                let seed = celebration.variation * 97 + index * 41
                let pieceWidth = CGFloat(7 + (seed * 7) % 12)
                let x = CGFloat((seed * 29) % 101) / 100 * size.width
                let drift = CGFloat(((seed * 17) % 45) - 22) / 100 * size.width
                let duration = 2.2 + Double((seed * 23) % 2300) / 1000
                let delay = -Double((seed * 13) % 1800) / 1000

                RoundedRectangle(cornerRadius: index.isMultiple(of: 3) ? pieceWidth : 2)
                    .fill(palette[index % palette.count])
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.black.opacity(0.45), lineWidth: 1))
                    .frame(width: index.isMultiple(of: 5) ? pieceWidth * 1.8 : pieceWidth, height: index.isMultiple(of: 5) ? pieceWidth * 0.6 : pieceWidth * 1.7)
                    .position(x: x, y: animateConfetti ? size.height + 90 : -90)
                    .offset(x: animateConfetti ? drift : 0)
                    .rotationEffect(.degrees(animateConfetti ? Double((seed * 31) % 720) : 0))
                    .animation(.linear(duration: duration).repeatForever(autoreverses: false).delay(delay), value: animateConfetti)
            }
        }
        .allowsHitTesting(false)
    }
}

enum SpinVisualMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case wheel = "Wheel"

    var id: String { rawValue }
}

@MainActor
final class NameSnapViewModel: ObservableObject {
    @Published var rawInput: String = ""
    @Published var entries: [NameEntry] = []
    @Published var selectedName: String = ""
    @Published var isSpinning = false
    @Published var noRepeatMode = true
    @Published var pickedIds: Set<UUID> = []
    @Published var history: [WinnerRecord] = []
    @Published var visualMode: SpinVisualMode = .classic
    @Published var wheelIndex: Int = 0

    private var lastAddedBatch: [UUID] = []

    var activeEntries: [NameEntry] { entries.filter { $0.isIncluded } }
    var wheelBaseEntries: [NameEntry] { activeEntries }

    var availableEntries: [NameEntry] {
        if !noRepeatMode { return activeEntries }
        return activeEntries.filter { !pickedIds.contains($0.id) }
    }

    private func parseNames(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",\n")
        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "^[0-9]+[\\.)-]?\\s*", with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
    }

    private func writeInputNames(_ names: [String]) {
        rawInput = names.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }

    var parsedInputNames: [String] {
        parseNames(from: rawInput)
    }

    func removeInputName(at index: Int) {
        var names = parsedInputNames
        guard names.indices.contains(index) else { return }
        names.remove(at: index)
        writeInputNames(names)
    }

    func appendInputName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var names = parsedInputNames
        names.append(trimmed)
        writeInputNames(names)
    }

    func appendInputText(_ text: String) {
        let incoming = parseNames(from: text)
        guard !incoming.isEmpty else { return }
        var names = parsedInputNames
        names.append(contentsOf: incoming)
        writeInputNames(names)
    }

    func updateInputName(at index: Int, to newValue: String) {
        var names = parsedInputNames
        guard names.indices.contains(index) else { return }
        names[index] = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        names = names.filter { !$0.isEmpty }
        writeInputNames(names)
    }

    var poolEntriesForDisplay: [NameEntry] {
        if !noRepeatMode { return entries }
        return entries.filter { $0.isIncluded && !pickedIds.contains($0.id) }
    }

    private var wheelMinimumRows: Int { 50_000 }
    private var wheelMaximumRows: Int { 200_000 }
    private var wheelRowsPerEntry: Int { 2_500 }

    var wheelVirtualRowCount: Int {
        let baseCount = wheelBaseEntries.count
        guard baseCount > 0 else { return 0 }
        return min(wheelMaximumRows, max(wheelMinimumRows, baseCount * wheelRowsPerEntry))
    }

    private func wrappedModulo(_ value: Int, modulus: Int) -> Int {
        guard modulus > 0 else { return 0 }
        let remainder = value % modulus
        return remainder >= 0 ? remainder : remainder + modulus
    }

    private func centeredWheelIndex(forBaseOffset baseOffset: Int) -> Int {
        let baseCount = wheelBaseEntries.count
        let total = wheelVirtualRowCount
        guard baseCount > 0, total > 0 else { return 0 }

        let safeOffset = wrappedModulo(baseOffset, modulus: baseCount)
        var center = total / 2
        center -= center % baseCount
        if center + safeOffset >= total {
            center = max(0, center - baseCount)
        }
        return center + safeOffset
    }

    func wheelEntry(at row: Int) -> NameEntry? {
        let base = wheelBaseEntries
        guard !base.isEmpty else { return nil }
        let offset = wrappedModulo(row, modulus: base.count)
        return base[offset]
    }

    private func renumberPoolEntries() {
        for index in entries.indices {
            entries[index].drawNumber = index + 1
        }
    }

    @discardableResult
    func addNamesFromInput() -> Int {
        addNames(parsedInputNames)
    }

    @discardableResult
    func addNames(_ names: [String]) -> Int {
        guard !names.isEmpty else { return 0 }
        // Keep labels contiguous even if this pool was edited before adding more names.
        renumberPoolEntries()
        var nextNumber = entries.count + 1
        let newOnes = names.map { item -> NameEntry in
            defer { nextNumber += 1 }
            return NameEntry(drawNumber: nextNumber, name: item)
        }
        entries.append(contentsOf: newOnes)
        lastAddedBatch = newOnes.map(\.id)
        pickedIds = pickedIds.intersection(Set(entries.map { $0.id }))

        normalizeWheelIndexIfNeeded(forceCenter: true)

        return newOnes.count
    }

    @discardableResult
    func undoLastAdd() -> Int {
        guard !lastAddedBatch.isEmpty else { return 0 }
        let previous = Set(lastAddedBatch)
        let before = entries.count
        entries.removeAll { previous.contains($0.id) }
        pickedIds.subtract(previous)
        renumberPoolEntries()
        normalizeWheelIndexIfNeeded(forceCenter: true)
        lastAddedBatch.removeAll()
        return before - entries.count
    }

    func currentWheelEntry() -> NameEntry? {
        wheelEntry(at: wheelIndex)
    }

    func spinWheelForward(step: Int) {
        let total = wheelVirtualRowCount
        guard total > 0 else { return }
        wheelIndex = wrappedModulo(wheelIndex + max(step, 1), modulus: total)
    }

    func normalizeWheelIndexIfNeeded(forceCenter: Bool = false) {
        let baseCount = wheelBaseEntries.count
        guard baseCount > 0 else {
            wheelIndex = 0
            return
        }

        let total = wheelVirtualRowCount
        guard total > 0 else {
            wheelIndex = 0
            return
        }

        let normalized = wrappedModulo(wheelIndex, modulus: total)
        let offset = wrappedModulo(normalized, modulus: baseCount)
        let edgeBuffer = max(baseCount * 3, 24)

        let needsRecentering = forceCenter || normalized < edgeBuffer || normalized >= (total - edgeBuffer)
        if needsRecentering {
            wheelIndex = centeredWheelIndex(forBaseOffset: offset)
        } else {
            wheelIndex = normalized
        }
    }

    func clampWheelIndexToWheelEntries() {
        let total = wheelVirtualRowCount
        guard total > 0 else {
            wheelIndex = 0
            return
        }
        wheelIndex = wrappedModulo(wheelIndex, modulus: total)
    }

    @discardableResult
    func commitCurrentWheelSelectionAsWinner(consumeWinner: Bool = true) -> String? {
        guard let winner = currentWheelEntry() else { return nil }
        return commitWinnerSnapshot(winner, consumeWinner: consumeWinner)
    }

    @discardableResult
    func commitWinnerSnapshot(_ winner: NameEntry, consumeWinner: Bool = true) -> String {
        let display = "\(winner.drawNumber). \(winner.name)"
        history.insert(WinnerRecord(drawNumber: winner.drawNumber, name: winner.name), at: 0)
        if history.count > 20 { history.removeLast() }
        if consumeWinner {
            markWinnerAsUsed(winner)
        }
        return display
    }

    private func markWinnerAsUsed(_ winner: NameEntry) {
        guard noRepeatMode else { return }
        pickedIds.insert(winner.id)
        if let idx = entries.firstIndex(where: { $0.id == winner.id }) {
            entries[idx].isIncluded = false
        }

        // Winner removal changes wheel pool size immediately; keep selection index valid synchronously.
        normalizeWheelIndexIfNeeded(forceCenter: true)
        clampWheelIndexToWheelEntries()
    }

    func commitSelectedNameAsWinnerIfNeeded() {
        let parts = selectedName.split(separator: ".", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let draw = Int(parts[0]) else { return }
        guard let winner = entries.first(where: { $0.drawNumber == draw && $0.name == parts[1] }) else { return }
        _ = commitWinnerSnapshot(winner)
    }

    func alignWheelHighlightToSelectedWinner() {
        let parts = selectedName.split(separator: ".", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let draw = Int(parts[0]) else { return }
        guard let baseIndex = wheelBaseEntries.firstIndex(where: { $0.drawNumber == draw && $0.name == parts[1] }) else { return }
        wheelIndex = centeredWheelIndex(forBaseOffset: baseIndex)
        normalizeWheelIndexIfNeeded(forceCenter: true)
    }

    func clearInputList() { rawInput = "" }

    func toggle(_ entry: NameEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].isIncluded.toggle()
    }

    func resetThisPool() {
        for index in entries.indices { entries[index].isIncluded = true }
        pickedIds.removeAll()
        selectedName = ""
        history.removeAll()
        normalizeWheelIndexIfNeeded(forceCenter: true)
    }

    func clearThisPool() {
        entries.removeAll()
        pickedIds.removeAll()
        selectedName = ""
        history.removeAll()
        lastAddedBatch.removeAll()
        wheelIndex = 0
    }

    func removeEntry(_ entry: NameEntry) {
        entries.removeAll { $0.id == entry.id }
        pickedIds.remove(entry.id)
        renumberPoolEntries()
        normalizeWheelIndexIfNeeded(forceCenter: true)
    }

    func spin() {
        guard !isSpinning else { return }

        if activeEntries.isEmpty {
            selectedName = "Add contestants to start spinning"
            return
        }

        let pool: [NameEntry]
        switch visualMode {
        case .classic:
            pool = availableEntries
            if pool.isEmpty {
                selectedName = "All Contestants Picked!"
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
        case .wheel:
            // Wheel mode intentionally ignores no-repeat consumption so spins remain infinite.
            pool = wheelBaseEntries
        }

        isSpinning = true

        switch visualMode {
        case .classic:
            let ticks = Int.random(in: 14...24)
            for i in 0..<ticks {
                let delay = Double(i) * 0.055
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    self.selectedName = pool.randomElement()?.name ?? ""
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if i == ticks - 1 { self.finishSpin(pool: pool) }
                }
            }
        case .wheel:
            normalizeWheelIndexIfNeeded(forceCenter: true)
            let baseCount = max(pool.count, 1)
            let currentOffset = wrappedModulo(wheelIndex, modulus: baseCount)
            let targetOffset = Int.random(in: 0..<baseCount)
            let fullTurns = Int.random(in: 12...24)
            let travelToTarget = wrappedModulo(targetOffset - currentOffset, modulus: baseCount)
            let totalTravel = (fullTurns * baseCount) + travelToTarget

            let ticks = Int.random(in: 34...54)
            var moved = 0
            for i in 0..<ticks {
                let progress = Double(i + 1) / Double(ticks)
                let eased = 1.0 - pow(1.0 - progress, 2.2)
                let targetMoved = Int((Double(totalTravel) * eased).rounded())
                let step = max(1, targetMoved - moved)
                moved = targetMoved

                let delay = (Double(i) * 0.034) + (Double(i * i) * 0.00062)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    self.spinWheelForward(step: step)
                    self.normalizeWheelIndexIfNeeded()
                    if i % 2 == 0 || i == ticks - 1 {
                        self.selectedName = self.currentWheelEntry()?.name ?? ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if i == ticks - 1 { self.finishSpin(pool: pool) }
                }
            }
        }
    }

    private func finishSpin(pool: [NameEntry]) {
        let winner: NameEntry?
        if visualMode == .wheel {
            winner = currentWheelEntry() ?? pool.randomElement()
        } else {
            winner = pool.randomElement()
        }
        guard let winner else { isSpinning = false; return }
        selectedName = "\(winner.drawNumber). \(winner.name)"
        normalizeWheelIndexIfNeeded(forceCenter: true)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSpinning = false
    }
}

@MainActor
final class NameSnapPurchaseManager: ObservableObject {
    enum Plan {
        case lifetime
        case monthly
    }

    @Published var isUnlimitedUnlocked = false
    @Published var lifetimeProduct: Product?
    @Published var monthlyProduct: Product?
    @Published private(set) var storeEnvironment: AppStore.Environment?

    private let lifetimeProductIds = [
        "namesnap.unlimited_lifetime_699"
    ]
    private let monthlyProductIds = [
        "namesnap.unlimited_monthly_099"
    ]

    private var allProductIds: [String] {
        lifetimeProductIds + monthlyProductIds
    }

    var isTestStoreEnvironment: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-test-store") ||
            ProcessInfo.processInfo.environment["NAMESNAP_UI_TEST_STORE"] == "1" {
            return true
        }
        #endif

        return storeEnvironment == .sandbox || storeEnvironment == .xcode
    }

    init() {
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: allProductIds)
            lifetimeProduct = products.first(where: { lifetimeProductIds.contains($0.id) })
            monthlyProduct = products.first(where: { monthlyProductIds.contains($0.id) })
        } catch {
            print("Product load failed: \(error.localizedDescription)")
        }
    }

    func refreshEntitlements() async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["NAMESNAP_UI_TEST_PRODUCTION_ENTITLEMENT"] == "1" {
            isUnlimitedUnlocked = true
            storeEnvironment = .production
            return
        } else if ProcessInfo.processInfo.environment["NAMESNAP_UI_TEST_ENTITLEMENT"] == "1" {
            isUnlimitedUnlocked = true
            storeEnvironment = .sandbox
            return
        }
        #endif

        isUnlimitedUnlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            storeEnvironment = transaction.environment
            if lifetimeProductIds.contains(transaction.productID) || monthlyProductIds.contains(transaction.productID) {
                isUnlimitedUnlocked = true
                return
            }
        }
    }

    func purchase(plan: Plan) async -> Bool {
        if lifetimeProduct == nil && monthlyProduct == nil {
            await loadProducts()
        }

        let product: Product?
        switch plan {
        case .lifetime:
            product = lifetimeProduct
        case .monthly:
            product = monthlyProduct
        }
        guard let product else { return false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                storeEnvironment = transaction.environment
                isUnlimitedUnlocked = true
                await transaction.finish()
                return true
            default:
                return false
            }
        } catch {
            print("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}

struct ContentView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var vm = NameSnapViewModel()
    @StateObject private var purchases = NameSnapPurchaseManager()
    @State private var showCenterAlert = false
    @State private var centerAlertText = ""
    @State private var centerAlertScale: CGFloat = 0.7
    @State private var pulseAddButton = false
    @State private var inputDraftName = ""
    @State private var showClearPoolConfirm = false
    @State private var showResetPoolConfirm = false
    @State private var showNoRepeatToggleConfirm = false
    @State private var noRepeatToggleUIValue: Bool = true
    @State private var pendingNoRepeatValue: Bool = true
    @State private var suppressNoRepeatToggleConfirm = false
    @State private var suppressNextWheelSettleCommit = false
    @State private var showUpgradeConfirm = false
    @State private var showDuplicateConfirm = false
    @State private var purchasingPlan: NameSnapPurchaseManager.Plan? = nil
    @State private var upgradeErrorText: String?
    @State private var showSoundOnHint = false
    @State private var didRunLaunchSilentCheck = false
    @State private var didShowWinnerForCurrentSpin = false
    @State private var flashIndex = 0
    @State private var showWinnerFlash = false
    @State private var winnerCelebration: WinnerCelebration?
    @State private var winnerAudioPlayer: AVAudioPlayer?
    @State private var winnerAudioStopWorkItem: DispatchWorkItem?
    @State private var wheelSettleWorkItem: DispatchWorkItem?
    @State private var isWheelSwipeSession = false
    @State private var suppressWheelSettle = false
    @State private var isButtonWheelSpin = false
    @State private var spinWinnerLockUntil: Date = .distantPast
    @State private var winnerSyncWorkItem: DispatchWorkItem?
    @State private var winnerRemovalWorkItem: DispatchWorkItem?
    @State private var winnerRemovalSequence: Int = 0
    @State private var pendingWinnerSnapshot: NameEntry?
    @State private var pendingWinnerDisplay: String = ""
    @State private var pendingNamesForAddition: [String] = []
    @State private var pendingDuplicateInputNames: [String] = []
    @State private var didRunThresholdPaywallCheck = false
    @State private var didConfigureScreenshotFixture = false

    private let flashColors: [Color] = [.pink, .yellow, .cyan, .green, .orange, .purple]
    private let freeContestantLimit = 16
    private let privacyPolicyURL = URL(string: "https://getnamesnap.web.app/privacy")!
    private let standardEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private var shouldShowUpgradeForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-upgrade")
        #else
        false
        #endif
    }

    private var shouldTriggerThresholdPaywallForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-threshold-paywall") ||
            ProcessInfo.processInfo.environment["NAMESNAP_UI_THRESHOLD"] == "1"
        #else
        false
        #endif
    }

    private var shouldSimulateTestEntitlementForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-test-entitlement") ||
            ProcessInfo.processInfo.environment["NAMESNAP_UI_TEST_ENTITLEMENT"] == "1"
        #else
        false
        #endif
    }

    private var shouldSimulateProductionEntitlementForUITesting: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["NAMESNAP_UI_TEST_PRODUCTION_ENTITLEMENT"] == "1"
        #else
        false
        #endif
    }

    private var thresholdContestantCountForUITesting: Int {
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["NAMESNAP_UI_CONTESTANT_COUNT"],
           let count = Int(value), count > 0 {
            return count
        }
        #endif
        return freeContestantLimit + 1
    }

    private var screenshotFixtureStateForUITesting: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["NAMESNAP_UI_SCREENSHOT_STATE"]
            ?? screenshotFixtureArgumentValue("-ui-screenshot-state")
        #else
        nil
        #endif
    }

    private var screenshotFixtureNamesForUITesting: [String] {
        #if DEBUG
        guard let rawNames = ProcessInfo.processInfo.environment["NAMESNAP_UI_SCREENSHOT_NAMES"]
            ?? screenshotFixtureArgumentValue("-ui-screenshot-names") else {
            return []
        }
        return rawNames
            .split(separator: "|", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        #else
        return []
        #endif
    }

    private func screenshotFixtureArgumentValue(_ key: String) -> String? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let keyIndex = arguments.firstIndex(of: key) else { return nil }
        let valueIndex = arguments.index(after: keyIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
        #else
        return nil
        #endif
    }

    private var lifetimePriceText: String {
        purchases.lifetimeProduct?.displayPrice ?? "$6.99"
    }

    private var monthlyPriceText: String {
        purchases.monthlyProduct?.displayPrice ?? "$0.99"
    }

    private var lifetimePurchaseButton: some View {
        Button(purchasingPlan == .lifetime ? "Purchasing…" : "Unlock Lifetime \(lifetimePriceText)") {
            dismissKeyboard()
            guard purchasingPlan == nil else { return }
            purchasingPlan = .lifetime
            upgradeErrorText = nil
            Task {
                let success = await purchases.purchase(plan: .lifetime)
                purchasingPlan = nil
                if success {
                    withAnimation { showUpgradeConfirm = false }
                    showBigAlert("✅ Unlimited Unlocked")
                    let namesToAdd = pendingNamesForAddition
                    pendingNamesForAddition.removeAll()
                    addNamesToPoolNow(namesToAdd)
                } else {
                    upgradeErrorText = "Couldn’t complete purchase. Check connection and try again."
                }
            }
        }
        .buttonStyle(NameSnapButtonStyle(tone: .primary))
        .font(titleFamilyFont(size: 13))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .disabled(purchasingPlan != nil)
    }

    private var titleFont: Font {
        if UIFont(name: "RubikMonoOne-Regular", size: 38) != nil {
            return .custom("RubikMonoOne-Regular", size: 38)
        }
        if UIFont(name: "Rubik Mono One", size: 38) != nil {
            return .custom("Rubik Mono One", size: 38)
        }
        return .system(size: 38, weight: .black, design: .rounded)
    }

    private func titleFamilyFont(size: CGFloat) -> Font {
        if UIFont(name: "RubikMonoOne-Regular", size: size) != nil {
            return .custom("RubikMonoOne-Regular", size: size)
        }
        if UIFont(name: "Rubik Mono One", size: size) != nil {
            return .custom("Rubik Mono One", size: size)
        }
        return .system(size: size, weight: .black, design: .rounded)
    }

    private func alertParts(from text: String) -> (symbol: String?, message: String) {
        guard let first = text.first else { return (nil, text) }
        let firstScalars = String(first).unicodeScalars
        let isPlainLetterOrNumber = firstScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
        guard !isPlainLetterOrNumber else { return (nil, text) }

        let message = text.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return (nil, text) }
        return (String(first), message)
    }

    @ViewBuilder
    private func centerAlertLabel(_ text: String) -> some View {
        symbolTitleLabel(text, textSize: 24, symbolSize: 28)
    }

    @ViewBuilder
    private func symbolTitleLabel(_ text: String, textSize: CGFloat, symbolSize: CGFloat) -> some View {
        let parts = alertParts(from: text)
        HStack(spacing: 10) {
            if let symbol = parts.symbol {
                centerAlertSymbol(symbol, size: symbolSize)
            }
            Text(parts.message)
                .font(titleFamilyFont(size: textSize))
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func centerAlertSymbol(_ symbol: String, size: CGFloat = 28) -> some View {
        if let assetName = emojiAssetName(for: symbol), let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size + 8, height: size + 8)
                .accessibilityLabel(emojiAccessibilityLabel(for: symbol))
        } else {
            Text(verbatim: symbol)
                .font(.system(size: size, weight: .regular, design: .default))
                .accessibilityLabel(emojiAccessibilityLabel(for: symbol))
        }
    }

    private func emojiAssetName(for symbol: String) -> String? {
        let normalized = normalizedEmojiSymbol(symbol)
        if normalized.contains("✅") || normalized.contains("✔") { return "success_emoji" }
        if normalized.contains("🎉") { return "party_popper_emoji" }
        if normalized.contains("✨") { return "sparkle_emoji" }
        if normalized.contains("↩") { return "undo_emoji" }
        if normalized.contains("🧹") { return "broom_emoji" }
        if normalized.contains("⚠") { return "warning_emoji" }
        if normalized.contains("♻") { return "recycle_emoji" }
        if normalized.contains("🔈") { return "sound_emoji" }
        if normalized.contains("🔁") { return "repeat_emoji" }
        return nil
    }

    private func emojiAccessibilityLabel(for symbol: String) -> String {
        let normalized = normalizedEmojiSymbol(symbol)
        if normalized.contains("✅") || normalized.contains("✔") { return "Success" }
        if normalized.contains("🎉") { return "Winner" }
        if normalized.contains("✨") { return "Upgrade" }
        if normalized.contains("↩") { return "Undo" }
        if normalized.contains("🧹") { return "Cleared" }
        if normalized.contains("⚠") { return "Warning" }
        if normalized.contains("♻") { return "Reset" }
        if normalized.contains("🔈") { return "Sound" }
        if normalized.contains("🔁") { return "Repeat" }
        return "Status"
    }

    private func normalizedEmojiSymbol(_ symbol: String) -> String {
        symbol
            .replacingOccurrences(of: "\u{FE0E}", with: "")
            .replacingOccurrences(of: "\u{FE0F}", with: "")
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func runLaunchSilentModeCheckIfNeeded() {
        guard !didRunLaunchSilentCheck else { return }
        didRunLaunchSilentCheck = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            // Evaluate after a short delay so the audio session has time to settle on fresh launch.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let settledSession = AVAudioSession.sharedInstance()
                #if targetEnvironment(simulator)
                let shouldShowSilentHint = settledSession.outputVolume <= 0.01
                #else
                let shouldShowSilentHint = settledSession.secondaryAudioShouldBeSilencedHint
                #endif
                if shouldShowSilentHint {
                    withAnimation { showSoundOnHint = true }
                }
            }
        } catch {
            print("Launch audio session check failed: \(error.localizedDescription)")
        }
    }

    private func configureScreenshotFixtureIfNeeded() -> Bool {
        #if DEBUG
        guard !didConfigureScreenshotFixture,
              let state = screenshotFixtureStateForUITesting,
              !state.isEmpty,
              !screenshotFixtureNamesForUITesting.isEmpty else {
            return false
        }
        didConfigureScreenshotFixture = true

        let names = screenshotFixtureNamesForUITesting
        vm.rawInput = names.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        switch state {
        case "input":
            break
        case "added":
            _ = vm.addNames(names)
            centerAlertText = "✅ Names Added"
            centerAlertScale = 1
            showCenterAlert = true
        case "classic":
            _ = vm.addNames(names)
            vm.visualMode = .classic
        case "wheel":
            _ = vm.addNames(names)
            vm.visualMode = .wheel
        case "reset-confirm":
            _ = vm.addNames(names)
            vm.visualMode = .wheel
            showResetPoolConfirm = true
        case "winner":
            _ = vm.addNames(names)
            vm.visualMode = .wheel
            let winnerIndex = min(6, names.count - 1)
            didShowWinnerForCurrentSpin = true
            suppressWheelSettle = true
            vm.selectedName = "\(winnerIndex + 1). \(names[winnerIndex])"
            vm.history = [WinnerRecord(drawNumber: winnerIndex + 1, name: names[winnerIndex])]
            winnerCelebration = WinnerCelebration(displayText: vm.selectedName, variation: 11)
        case "history":
            _ = vm.addNames(names)
            vm.visualMode = .classic
            let winnerIndices = [16, 14, 11].filter { names.indices.contains($0) }
            vm.history = winnerIndices.map { WinnerRecord(drawNumber: $0 + 1, name: names[$0]) }
            if let winnerIndex = winnerIndices.first {
                vm.selectedName = "\(winnerIndex + 1). \(names[winnerIndex])"
            }
        case "upgrade":
            pendingNamesForAddition = names
            showUpgradeConfirm = true
        default:
            return false
        }

        return true
        #else
        return false
        #endif
    }

    private func handleViewAppear() {
        noRepeatToggleUIValue = vm.noRepeatMode
        pendingNoRepeatValue = vm.noRepeatMode

        if configureScreenshotFixtureIfNeeded() {
            didRunLaunchSilentCheck = true
        } else {
            runLaunchSilentModeCheckIfNeeded()
        }

        if screenshotFixtureStateForUITesting == nil,
           shouldTriggerThresholdPaywallForUITesting,
           !didRunThresholdPaywallCheck {
            didRunThresholdPaywallCheck = true
            if shouldSimulateTestEntitlementForUITesting || shouldSimulateProductionEntitlementForUITesting {
                purchases.isUnlimitedUnlocked = true
            }
            let names = (1...thresholdContestantCountForUITesting).map { "Contestant \($0)" }
            vm.rawInput = names.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            DispatchQueue.main.async {
                beginAddingNames(names)
            }
        } else if shouldShowUpgradeForUITesting {
            showUpgradeConfirm = true
        }
    }

    private func shouldPresentPaywall(currentCount: Int, incomingCount: Int) -> Bool {
        guard incomingCount > 0 else { return false }
        guard (currentCount + incomingCount) > freeContestantLimit else { return false }
        return !purchases.isUnlimitedUnlocked
    }

    private func normalizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func hasPoolDuplicates(in names: [String]) -> Bool {
        let existingNames = Set(vm.entries.map { normalizedName($0.name) })
        return names.contains { existingNames.contains(normalizedName($0)) }
    }

    private func poolDuplicateCount(in names: [String]) -> Int {
        let existingNames = Set(vm.entries.map { normalizedName($0.name) })
        return names.filter { existingNames.contains(normalizedName($0)) }.count
    }

    private func namesExcludingPoolDuplicates(_ names: [String]) -> [String] {
        let existingNames = Set(vm.entries.map { normalizedName($0.name) })
        return names.filter { !existingNames.contains(normalizedName($0)) }
    }

    private func beginAddingNames(_ names: [String]) {
        guard !names.isEmpty else {
            showBigAlert("No New Names to Add")
            return
        }

        if shouldPresentPaywall(currentCount: vm.entries.count, incomingCount: names.count) {
            pendingNamesForAddition = names
            withAnimation { showUpgradeConfirm = true }
            return
        }

        addNamesToPoolNow(names)
    }

    private func addNamesToPoolNow(_ names: [String]) {
        if vm.visualMode == .wheel {
            suppressNextWheelSettleCommit = true
            suppressWheelSettle = true
        }

        let added = vm.addNames(names)
        guard added > 0 else {
            if vm.visualMode == .wheel {
                suppressWheelSettle = false
                suppressNextWheelSettleCommit = false
            }
            return
        }

        showBigAlert("✅ Names Added")
        withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
            pulseAddButton = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            pulseAddButton = false
        }

        if vm.visualMode == .wheel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                suppressWheelSettle = false
                suppressNextWheelSettleCommit = false
            }
        }
    }

    private func showBigAlert(_ text: String) {
        centerAlertText = text
        centerAlertScale = 0.65
        withAnimation(.spring(response: 0.32, dampingFraction: 0.62)) {
            showCenterAlert = true
            centerAlertScale = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard screenshotFixtureStateForUITesting != "winner" else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showCenterAlert = false
            }
        }
    }


    private func triggerWinnerEffects(name: String) {
        let nextCelebration = WinnerCelebration(displayText: name)
        winnerCelebration = nextCelebration
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        playCelebrationSoundReliably(audioName: nextCelebration.audioName)
        if !reduceMotion {
            showWinnerFlash = true
            flashIndex = 0

            // Pulse the whole display for the length of the winner soundtrack.
            // The 0.55-second cadence stays well below rapid-strobe territory.
            for step in 0..<10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(step) * 0.55)) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        flashIndex = step % flashColors.count
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.65) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showWinnerFlash = false
                }
            }
        }
    }

    private func dismissWinnerCelebration() {
        winnerAudioStopWorkItem?.cancel()
        winnerAudioPlayer?.stop()
        winnerAudioPlayer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            winnerCelebration = nil
        }
    }

    private func playCelebrationSoundReliably(audioName: String) {
        playRandomCelebrationSound(preferredName: audioName)

        // Rare simulator/audio-session race: retry once if playback did not start.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if winnerAudioPlayer?.isPlaying != true {
                playRandomCelebrationSound(preferredName: audioName)
            }
        }
    }

    private func playRandomCelebrationSound(preferredName: String? = nil) {
        let customNames = WinnerCelebration.audioNames
        let extensions = ["mp3", "wav", "m4a", "aiff"]

        winnerAudioStopWorkItem?.cancel()
        winnerAudioPlayer?.stop()
        winnerAudioPlayer = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }

        var availableURLs: [(name: String, url: URL)] = []
        for name in customNames {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    availableURLs.append((name, url))
                }
            }
        }

        guard !availableURLs.isEmpty else {
            print("No bundled winner audio files found in app bundle.")
            return
        }

        let preferredURLs = availableURLs.filter { $0.name == preferredName }
        let fallbackURLs = availableURLs.filter { $0.name != preferredName }.shuffled()
        for item in preferredURLs + fallbackURLs {
            let url = item.url
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.currentTime = 0
                player.numberOfLoops = player.duration < 5.8 ? -1 : 0
                player.volume = 0.76

                guard player.play() else {
                    print("Audio play() returned false for \(url.lastPathComponent)")
                    continue
                }

                winnerAudioPlayer = player

                let stopItem = DispatchWorkItem {
                    player.stop()
                    player.currentTime = 0
                    if winnerAudioPlayer === player {
                        winnerAudioPlayer = nil
                    }
                }
                winnerAudioStopWorkItem = stopItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.8, execute: stopItem)
                return
            } catch {
                print("Failed to play custom SFX \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        print("Winner audio failed for all bundled candidates.")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.pageGradient
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("NAMESNAP")
                                    .font(titleFont)
                                    .foregroundStyle(NSTheme.ink)
                                    .shadow(color: NSTheme.skyBlue, radius: 0, x: 3, y: 3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)

                                Text("RANDOM PICKER")
                                    .font(titleFamilyFont(size: 9))
                                    .foregroundStyle(NSTheme.violet)
                                    .tracking(2.2)
                            }

                            Spacer(minLength: 6)

                            Text(vm.entries.isEmpty ? "READY TO BUILD" : "\(vm.availableEntries.count) ELIGIBLE")
                                .font(titleFamilyFont(size: 8))
                                .foregroundStyle(NSTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(NSTheme.yellow)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(NSTheme.ink, lineWidth: 2))
                                .shadow(color: NSTheme.violet, radius: 0, x: 3, y: 4)
                        }
                        .padding(.horizontal, 2)

                        card {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("CONTESTANT LIST")
                                            .font(titleFamilyFont(size: 15))
                                            .foregroundStyle(NSTheme.ink)

                                        Text("One name per line. Numbers stay with the pool.")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(NSTheme.ink.opacity(0.64))
                                    }

                                    Spacer()

                                    Text("\(vm.parsedInputNames.count) READY")
                                        .font(titleFamilyFont(size: 7))
                                        .foregroundStyle(NSTheme.ink)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 7)
                                        .background(NSTheme.yellow.opacity(0.88))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(NSTheme.ink, lineWidth: 1.5))
                                }

                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(NSTheme.fieldGradient)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(NSTheme.ink, lineWidth: 2.5)
                                        )
                                        .shadow(color: NSTheme.skyBlue, radius: 0, x: 4, y: 5)

                                    InlineTrashTextView(
                                        text: $vm.rawInput,
                                        onDeleteLine: { idx in
                                            vm.removeInputName(at: idx)
                                        }
                                    )
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.clear)
                                }

                                Button("ADD THESE NAMES TO POOL") {
                                    dismissKeyboard()
                                    let incoming = vm.parsedInputNames
                                    guard !incoming.isEmpty else { return }

                                    if hasPoolDuplicates(in: incoming) {
                                        pendingDuplicateInputNames = incoming
                                        withAnimation { showDuplicateConfirm = true }
                                        return
                                    }

                                    beginAddingNames(incoming)
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .primary))
                                .font(titleFamilyFont(size: 14))
                                .frame(maxWidth: .infinity)
                                .scaleEffect(pulseAddButton ? 0.96 : 1)

                                HStack(spacing: 10) {
                                    Button("UNDO LAST ADD") {
                                        dismissKeyboard()
                                        let removed = vm.undoLastAdd()
                                        guard removed > 0 else { return }
                                        showBigAlert("↩️ Undid \(removed)")
                                    }
                                    .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                    .font(titleFamilyFont(size: 9))
                                    .frame(maxWidth: .infinity)

                                    Button("CLEAR THIS LIST") {
                                        dismissKeyboard()
                                        vm.clearInputList()
                                        showBigAlert("🧹 List Cleared")
                                    }
                                    .buttonStyle(NameSnapButtonStyle(tone: .destructive))
                                    .font(titleFamilyFont(size: 9))
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }

                        card {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("DRAW SETUP")
                                    .font(titleFamilyFont(size: 14))
                                    .foregroundStyle(NSTheme.ink)

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("NO REPEATS")
                                            .font(titleFamilyFont(size: 10))
                                            .foregroundStyle(NSTheme.ink)
                                        Text("Winners sit out until reset")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(NSTheme.ink.opacity(0.62))
                                    }
                                    Spacer()
                                    Toggle("", isOn: $noRepeatToggleUIValue)
                                        .labelsHidden()
                                        .tint(NSTheme.violet)
                                        .onChange(of: noRepeatToggleUIValue) { newValue in
                                            guard !suppressNoRepeatToggleConfirm else { return }
                                            pendingNoRepeatValue = newValue
                                            withAnimation { showNoRepeatToggleConfirm = true }
                                        }
                                }

                                HStack(spacing: 10) {
                                    ForEach(SpinVisualMode.allCases) { mode in
                                        Button(mode == .classic ? "QUICK PICK" : "SPIN WHEEL") {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                vm.visualMode = mode
                                            }
                                        }
                                        .buttonStyle(NameSnapModeButtonStyle(isSelected: vm.visualMode == mode))
                                        .accessibilityAddTraits(vm.visualMode == mode ? .isSelected : [])
                                    }
                                }
                            }
                        }

                        if vm.visualMode == .classic {
                            Button {
                                dismissKeyboard()
                                if vm.activeEntries.isEmpty && !vm.entries.isEmpty {
                                    showBigAlert("⚠️ All winners have been selected")
                                } else {
                                    vm.spin()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [NSTheme.lavender, NSTheme.skyBlue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 258, height: 258)
                                        .overlay(Circle().stroke(NSTheme.ink, lineWidth: 4))
                                        .shadow(color: NSTheme.violet, radius: 0, x: 8, y: 10)

                                    Circle()
                                        .fill(NameSnapButtonTone.warm.fill)
                                        .frame(width: 166, height: 166)
                                        .overlay(Circle().stroke(NSTheme.ink, lineWidth: 3))
                                        .shadow(color: NSTheme.ink, radius: 0, x: 4, y: 5)

                                    Text(vm.isSpinning ? "SPINNING" : "SPIN")
                                        .font(titleFamilyFont(size: vm.isSpinning ? 21 : 32))
                                        .foregroundStyle(NSTheme.ink)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.isSpinning || vm.entries.isEmpty)
                            .opacity(vm.entries.isEmpty ? 0.45 : 1)
                            .padding(.vertical, 6)
                        } else {
                            card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("SPIN WHEEL")
                                        .font(titleFamilyFont(size: 16))
                                        .foregroundStyle(NSTheme.ink)
                                    if vm.wheelVirtualRowCount == 0 {
                                        Text("No available contestants")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(NSTheme.ink.opacity(0.62))
                                            .frame(maxWidth: .infinity, minHeight: 140)
                                            .background(NSTheme.fieldGradient)
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NSTheme.ink, lineWidth: 2))
                                    } else {
                                        InfiniteWheelPicker(
                                            entries: vm.wheelBaseEntries,
                                            selection: $vm.wheelIndex,
                                            rowCount: vm.wheelVirtualRowCount,
                                            animateProgrammaticChanges: vm.isSpinning
                                        )
                                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                                        .contentShape(Rectangle())
                                    }

                                    Button(vm.isSpinning ? "SPINNING" : "SPIN THE WHEEL") {
                                        dismissKeyboard()
                                        if vm.activeEntries.isEmpty && !vm.entries.isEmpty {
                                            showBigAlert("⚠️ All winners have been selected")
                                        } else {
                                            isButtonWheelSpin = true
                                            suppressWheelSettle = true
                                            vm.spin()
                                        }
                                    }
                                    .buttonStyle(NameSnapButtonStyle(tone: .warm))
                                    .font(titleFamilyFont(size: 15))
                                    .frame(maxWidth: .infinity)
                                    .disabled(vm.isSpinning || vm.entries.isEmpty)
                                    .opacity(vm.entries.isEmpty ? 0.45 : 1)
                                }
                            }
                        }

                        if !vm.selectedName.isEmpty {
                            Text(vm.selectedName)
                                .font(titleFamilyFont(size: 24))
                                .foregroundStyle(NSTheme.ink)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.62)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [NSTheme.yellow, NSTheme.tan.opacity(0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NSTheme.ink, lineWidth: 3))
                                .shadow(color: NSTheme.violet, radius: 0, x: 6, y: 7)
                        }

                        if !vm.history.isEmpty {
                            card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("RECENT WINNERS")
                                        .font(titleFamilyFont(size: 14))
                                        .foregroundStyle(NSTheme.ink)
                                    ForEach(vm.history) { item in
                                        Text("• \(item.displayText)")
                                    }
                                }
                            }
                        }

                        if !vm.entries.isEmpty {
                            card {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("ACTIVE POOL")
                                            .font(titleFamilyFont(size: 14))
                                            .foregroundStyle(NSTheme.ink)
                                        Spacer()
                                        Text("\(vm.poolEntriesForDisplay.count) TOTAL")
                                            .font(titleFamilyFont(size: 7))
                                            .foregroundStyle(NSTheme.ink)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 7)
                                            .background(NSTheme.yellow.opacity(0.88))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(NSTheme.ink, lineWidth: 1.5))
                                    }
                                    ForEach(vm.poolEntriesForDisplay) { entry in
                                        HStack(spacing: 10) {
                                            Button {
                                                vm.toggle(entry)
                                            } label: {
                                                HStack(spacing: 10) {
                                                    Image(systemName: entry.isIncluded ? "checkmark.circle.fill" : "circle")
                                                        .foregroundStyle(entry.isIncluded ? NSTheme.violet : Color.gray)
                                                    Text("\(entry.drawNumber). \(entry.name)")
                                                        .foregroundStyle(NSTheme.ink)
                                                        .font(.body.weight(.semibold))
                                                    Spacer()
                                                }
                                                .padding(.vertical, 4)
                                            }
                                            .buttonStyle(.plain)

                                            Button {
                                                vm.removeEntry(entry)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(.red)
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(NSTheme.fieldGradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(NSTheme.ink.opacity(0.72), lineWidth: 1.5))
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 12)
                    }
                    .padding()
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 110)
                }
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .overlay {
                if showWinnerFlash {
                    flashColors[flashIndex % flashColors.count]
                        .opacity(0.14)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .overlay {
                if showCenterAlert {
                    centerAlertLabel(centerAlertText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .nameSnapActionModalSurface()
                        .scaleEffect(centerAlertScale)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay {
                if let celebration = winnerCelebration {
                    WinnerCelebrationOverlay(
                        celebration: celebration,
                        onDismiss: dismissWinnerCelebration,
                        onReset: {
                            dismissWinnerCelebration()
                            withAnimation { showResetPoolConfirm = true }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .overlay {
                if showResetPoolConfirm {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            symbolTitleLabel("♻️ Reset this pool?", textSize: 22, symbolSize: 24)

                            Text("This keeps names, but resets inclusion and no-repeat history.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NSTheme.ink.opacity(0.68))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    withAnimation { showResetPoolConfirm = false }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                .font(titleFamilyFont(size: 13))

                                Button("Reset Pool") {
                                    dismissKeyboard()
                                    suppressWheelSettle = true
                                    winnerSyncWorkItem?.cancel()
                                    winnerRemovalWorkItem?.cancel()
                                    pendingWinnerSnapshot = nil
                                    pendingWinnerDisplay = ""
                                    vm.resetThisPool()
                                    withAnimation { showResetPoolConfirm = false }
                                    showBigAlert("♻️ Pool Reset")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        suppressWheelSettle = false
                                    }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .warm))
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 560)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay {
                if showClearPoolConfirm {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            symbolTitleLabel("⚠️ Clear this pool?", textSize: 22, symbolSize: 24)

                            Text("This removes all names from the current pool.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NSTheme.ink.opacity(0.68))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    withAnimation { showClearPoolConfirm = false }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                .font(titleFamilyFont(size: 13))

                                Button("Clear Pool") {
                                    dismissKeyboard()
                                    suppressWheelSettle = true
                                    winnerSyncWorkItem?.cancel()
                                    winnerRemovalWorkItem?.cancel()
                                    pendingWinnerSnapshot = nil
                                    pendingWinnerDisplay = ""
                                    vm.clearThisPool()
                                    withAnimation { showClearPoolConfirm = false }
                                    showBigAlert("🧹 Pool Cleared")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        suppressWheelSettle = false
                                    }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .destructive))
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 560)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay {
                if showSoundOnHint {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            symbolTitleLabel("🔈 Better with sound on!", textSize: 22, symbolSize: 24)

                            Button("Gotcha") {
                                dismissKeyboard()
                                withAnimation { showSoundOnHint = false }
                            }
                            .buttonStyle(NameSnapButtonStyle(tone: .warm))
                            .font(titleFamilyFont(size: 13))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 560)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay {
                if showDuplicateConfirm {
                    let duplicateCount = poolDuplicateCount(in: pendingDuplicateInputNames)

                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            Text("Duplicates found")
                                .font(titleFamilyFont(size: 22))
                                .multilineTextAlignment(.center)

                            Text("\(duplicateCount) name\(duplicateCount == 1 ? "" : "s") already exist in this pool.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NSTheme.ink.opacity(0.68))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Skip duplicates") {
                                    let namesToAdd = namesExcludingPoolDuplicates(pendingDuplicateInputNames)
                                    pendingDuplicateInputNames.removeAll()
                                    withAnimation { showDuplicateConfirm = false }
                                    beginAddingNames(namesToAdd)
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                .font(titleFamilyFont(size: 13))

                                Button("Add all anyway") {
                                    let namesToAdd = pendingDuplicateInputNames
                                    pendingDuplicateInputNames.removeAll()
                                    withAnimation { showDuplicateConfirm = false }
                                    beginAddingNames(namesToAdd)
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .primary))
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 560)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay {
                if showUpgradeConfirm {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 0) {
                            ScrollView {
                                VStack(spacing: 12) {
                            symbolTitleLabel("✨ Upgrade to Unlimited?", textSize: 22, symbolSize: 24)

                            Text("Free supports up to \(freeContestantLimit) contestants.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.black.opacity(0.78))
                                .multilineTextAlignment(.center)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Unlimited contestants")
                                Text("• No account needed")
                                Text("• Restore purchases anytime")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.76))
                            .fixedSize(horizontal: false, vertical: true)

                            Text("Unlimited Monthly renews every month until canceled. Unlimited Lifetime is a one-time purchase.")
                                .font(.caption)
                                .foregroundStyle(.black.opacity(0.72))
                                .multilineTextAlignment(.center)

                            Group {
                                if dynamicTypeSize.isAccessibilitySize {
                                    VStack(spacing: 10) {
                                        lifetimePurchaseButton
                                        Button("Not Now") {
                                            dismissKeyboard()
                                            pendingNamesForAddition.removeAll()
                                            withAnimation { showUpgradeConfirm = false }
                                        }
                                        .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                        .font(titleFamilyFont(size: 13))
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Button("Not Now") {
                                            dismissKeyboard()
                                            pendingNamesForAddition.removeAll()
                                            withAnimation { showUpgradeConfirm = false }
                                        }
                                        .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                        .font(titleFamilyFont(size: 13))

                                        lifetimePurchaseButton
                                    }
                                }
                            }

                            Button(purchasingPlan == .monthly ? "Purchasing…" : "Or Monthly \(monthlyPriceText)") {
                                dismissKeyboard()
                                guard purchasingPlan == nil else { return }
                                purchasingPlan = .monthly
                                upgradeErrorText = nil
                                Task {
                                    let success = await purchases.purchase(plan: .monthly)
                                    purchasingPlan = nil
                                    if success {
                                        withAnimation { showUpgradeConfirm = false }
                                        showBigAlert("✅ Unlimited Unlocked")
                                        let namesToAdd = pendingNamesForAddition
                                        pendingNamesForAddition.removeAll()
                                        addNamesToPoolNow(namesToAdd)
                                    } else {
                                        upgradeErrorText = "Monthly plan unavailable or purchase cancelled."
                                    }
                                }
                            }
                            .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                            .font(titleFamilyFont(size: 12))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .disabled(purchasingPlan != nil)

                            Button("Restore Purchases") {
                                dismissKeyboard()
                                Task {
                                    await purchases.restorePurchases()
                                    if purchases.isUnlimitedUnlocked {
                                        withAnimation { showUpgradeConfirm = false }
                                        showBigAlert("✅ Unlimited Restored")
                                    } else {
                                        upgradeErrorText = "No previous purchases found on this Apple ID."
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.7))

                            if let upgradeErrorText {
                                Text(upgradeErrorText)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            }
                            .scrollBounceBehavior(.basedOnSize)

                            Divider()

                            Group {
                                if dynamicTypeSize.isAccessibilitySize {
                                    VStack(spacing: 6) {
                                        Link("Privacy Policy", destination: privacyPolicyURL)
                                        Link("Terms of Use", destination: standardEULAURL)
                                    }
                                } else {
                                    HStack(spacing: 12) {
                                        Link("Privacy Policy", destination: privacyPolicyURL)
                                        Link("Terms of Use", destination: standardEULAURL)
                                    }
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .tint(NSTheme.violet)
                            .padding(.vertical, 10)
                            .accessibilityElement(children: .contain)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? UIScreen.main.bounds.height * 0.88 : 390)
                        .frame(maxWidth: 620)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay {
                if showNoRepeatToggleConfirm {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            symbolTitleLabel("🔁 Change no-repeat setting?", textSize: 22, symbolSize: 24)

                            Text("This will reset the current pool and no-repeat history. Continue?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NSTheme.ink.opacity(0.68))
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    suppressNoRepeatToggleConfirm = true
                                    noRepeatToggleUIValue = vm.noRepeatMode
                                    pendingNoRepeatValue = vm.noRepeatMode
                                    suppressNoRepeatToggleConfirm = false
                                    withAnimation { showNoRepeatToggleConfirm = false }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                                .font(titleFamilyFont(size: 13))

                                Button("Confirm") {
                                    dismissKeyboard()
                                    let next = pendingNoRepeatValue

                                    // Dismiss first, then apply toggle + reset sequence.
                                    withAnimation { showNoRepeatToggleConfirm = false }

                                    DispatchQueue.main.async {
                                        suppressNoRepeatToggleConfirm = true
                                        vm.noRepeatMode = next
                                        noRepeatToggleUIValue = next

                                        winnerSyncWorkItem?.cancel()
                                        wheelSettleWorkItem?.cancel()
                                        pendingWinnerSnapshot = nil
                                        pendingWinnerDisplay = ""
                                        suppressNextWheelSettleCommit = true
                                        suppressWheelSettle = true
                                        vm.resetThisPool()
                                        pendingNoRepeatValue = next
                                        showBigAlert("♻️ Pool Reset")

                                        // Release guards after UI settles so no auto wheel winner sequence fires.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            suppressNoRepeatToggleConfirm = false
                                            suppressWheelSettle = false
                                            suppressNextWheelSettleCommit = false
                                        }
                                    }
                                }
                                .buttonStyle(NameSnapButtonStyle(tone: .warm))
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .frame(maxWidth: 560)
                        .nameSnapActionModalSurface()
                        .padding(.horizontal, 22)
                    }
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottom) {
                if !showUpgradeConfirm && winnerCelebration == nil && !vm.entries.isEmpty {
                    HStack(spacing: 12) {
                        Button("RESET POOL") { showResetPoolConfirm = true }
                            .buttonStyle(NameSnapButtonStyle(tone: .secondary))
                            .font(titleFamilyFont(size: 10))
                            .frame(maxWidth: .infinity)
                        Button("CLEAR POOL") { showClearPoolConfirm = true }
                            .buttonStyle(NameSnapButtonStyle(tone: .destructive))
                            .font(titleFamilyFont(size: 10))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(NSTheme.pageGradient)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(NSTheme.ink)
                            .frame(height: 2)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .onChange(of: vm.wheelIndex) { _ in
                guard vm.visualMode == .wheel else { return }
                vm.normalizeWheelIndexIfNeeded()

                #if DEBUG
                // The deterministic wheel fixture is a static visual inspection state,
                // not a simulated swipe. Keep it from scheduling a winner reveal.
                guard screenshotFixtureStateForUITesting != "wheel" else { return }
                #endif

                // During post-spin lock, keep winner frozen so manual-settle path can't re-commit a new name.
                guard Date() >= spinWinnerLockUntil else { return }

                // Critical: never overwrite selected winner while programmatic spin is still finalizing.
                guard !vm.isSpinning else { return }
                guard !suppressNextWheelSettleCommit else { return }

                if !didShowWinnerForCurrentSpin, let current = vm.currentWheelEntry() {
                    vm.selectedName = "\(current.drawNumber). \(current.name)"
                }
                guard !isButtonWheelSpin, !suppressWheelSettle else { return }

                // Manual swipe spin: commit winner when wheel settles.
                if !isWheelSwipeSession {
                    isWheelSwipeSession = true
                }

                wheelSettleWorkItem?.cancel()
                let settle = DispatchWorkItem {
                    isWheelSwipeSession = false
                    guard !suppressWheelSettle else { return }
                    guard !vm.activeEntries.isEmpty else { return }

                    // Prevent post-settle index churn from chaining through the entire pool.
                    suppressWheelSettle = true
                    spinWinnerLockUntil = Date().addingTimeInterval(0.9)

                    guard let winnerName = vm.commitCurrentWheelSelectionAsWinner(consumeWinner: vm.noRepeatMode) else {
                        vm.normalizeWheelIndexIfNeeded(forceCenter: true)
                        vm.clampWheelIndexToWheelEntries()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            suppressWheelSettle = false
                        }
                        return
                    }
                    vm.selectedName = winnerName
                    didShowWinnerForCurrentSpin = true
                    triggerWinnerEffects(name: winnerName)
                    // Keep wheel swipes infinite by recentering after each manual settle commit.
                    vm.normalizeWheelIndexIfNeeded(forceCenter: true)
                    vm.clampWheelIndexToWheelEntries()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        suppressWheelSettle = false
                    }
                }
                wheelSettleWorkItem = settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: settle)
            }
            .onChange(of: vm.activeEntries.map(\.id)) { _ in
                suppressWheelSettle = true
                vm.normalizeWheelIndexIfNeeded(forceCenter: true)
                vm.clampWheelIndexToWheelEntries()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    suppressWheelSettle = false
                }
            }
            .onChange(of: vm.wheelVirtualRowCount) { _ in
                vm.clampWheelIndexToWheelEntries()
            }
            .onAppear(perform: handleViewAppear)
            .onChange(of: vm.noRepeatMode) { newValue in
                if !showNoRepeatToggleConfirm {
                    noRepeatToggleUIValue = newValue
                    pendingNoRepeatValue = newValue
                }
            }
            .onChange(of: vm.isSpinning) { spinning in
                if spinning {
                    didShowWinnerForCurrentSpin = false
                    isWheelSwipeSession = false
                    wheelSettleWorkItem?.cancel()
                    winnerSyncWorkItem?.cancel()
                    pendingWinnerSnapshot = nil
                    pendingWinnerDisplay = ""
                    suppressWheelSettle = true
                } else {
                    // Freeze winner and suppress settle commits long enough for post-spin recenter churn to finish.
                    spinWinnerLockUntil = Date().addingTimeInterval(1.6)
                    wheelSettleWorkItem?.cancel()

                    // let wheel settle callbacks quiet down after programmatic spin
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        suppressWheelSettle = false
                        isButtonWheelSpin = false
                    }

                    if !didShowWinnerForCurrentSpin,
                       !vm.selectedName.isEmpty,
                       vm.selectedName != "All Contestants Picked!",
                       vm.selectedName != "Add contestants to start spinning" {
                        if vm.visualMode == .wheel, let wheelWinner = vm.currentWheelEntry() {
                            // Wheel is source-of-truth: commit + effects use the highlighted wheel entry.
                            let winnerText = vm.commitWinnerSnapshot(wheelWinner, consumeWinner: vm.noRepeatMode)
                            vm.selectedName = winnerText
                            didShowWinnerForCurrentSpin = true
                            triggerWinnerEffects(name: winnerText)
                        } else {
                            // Classic keeps selectedName-driven commit path.
                            vm.commitSelectedNameAsWinnerIfNeeded()
                            didShowWinnerForCurrentSpin = true
                            triggerWinnerEffects(name: vm.selectedName)
                        }
                    }
                }
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .nameSnapPanelSurface()
    }
}


private final class FullWidthPickerView: UIPickerView {
    override var intrinsicContentSize: CGSize {
        let inherited = super.intrinsicContentSize
        return CGSize(width: UIView.noIntrinsicMetric, height: inherited.height)
    }
}

private struct InfiniteWheelPicker: UIViewRepresentable {
    let entries: [NameEntry]
    @Binding var selection: Int
    let rowCount: Int
    let animateProgrammaticChanges: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = FullWidthPickerView()
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        context.coordinator.lastEntriesSignature = entriesSignature
        context.coordinator.lastRowCount = max(rowCount, 0)
        context.coordinator.synchronizeSelection(in: picker, animated: false)
        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.parent = self

        let newSignature = entriesSignature
        let newRowCount = max(rowCount, 0)
        let shouldReload = context.coordinator.lastEntriesSignature != newSignature || context.coordinator.lastRowCount != newRowCount

        if shouldReload {
            context.coordinator.lastEntriesSignature = newSignature
            context.coordinator.lastRowCount = newRowCount
            uiView.reloadAllComponents()
        }

        context.coordinator.synchronizeSelection(in: uiView, animated: animateProgrammaticChanges)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIPickerView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return CGSize(width: width, height: proposal.height ?? 140)
    }

    private var entriesSignature: String {
        let first = entries.first?.id.uuidString ?? "-"
        let last = entries.last?.id.uuidString ?? "-"
        return "\(entries.count)#\(first)#\(last)"
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: InfiniteWheelPicker
        var lastEntriesSignature = ""
        var lastRowCount = 0
        private var suppressSelectionCallback = false

        init(_ parent: InfiniteWheelPicker) {
            self.parent = parent
        }

        private var baseCount: Int { parent.entries.count }
        private var totalRows: Int { max(parent.rowCount, 0) }

        private func wrappedModulo(_ value: Int, modulus: Int) -> Int {
            guard modulus > 0 else { return 0 }
            let remainder = value % modulus
            return remainder >= 0 ? remainder : remainder + modulus
        }

        private func centeredRow(for row: Int) -> Int {
            let total = totalRows
            let base = baseCount
            guard total > 0, base > 0 else { return 0 }
            let offset = wrappedModulo(row, modulus: base)
            var center = total / 2
            center -= center % base
            if center + offset >= total {
                center = max(0, center - base)
            }
            return center + offset
        }

        private func rowNearEdge(_ row: Int) -> Bool {
            let total = totalRows
            let base = baseCount
            guard total > 0, base > 0 else { return false }
            let edge = max(base * 3, 24)
            return row < edge || row >= (total - edge)
        }

        func synchronizeSelection(in picker: UIPickerView, animated: Bool) {
            let total = totalRows
            guard total > 0 else { return }
            let normalized = wrappedModulo(parent.selection, modulus: total)
            let current = picker.selectedRow(inComponent: 0)
            guard current != normalized else { return }

            suppressSelectionCallback = true
            picker.selectRow(normalized, inComponent: 0, animated: animated)
            suppressSelectionCallback = false
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            totalRows
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            34
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            max(pickerView.bounds.width, 1)
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? UILabel()
            label.textAlignment = .center
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = .label
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            guard baseCount > 0 else {
                label.text = nil
                return label
            }
            let entry = parent.entries[wrappedModulo(row, modulus: baseCount)]
            label.text = "\(entry.drawNumber). \(entry.name)"
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            guard !suppressSelectionCallback else { return }
            let total = totalRows
            guard total > 0 else { return }

            var normalized = wrappedModulo(row, modulus: total)
            if rowNearEdge(normalized) {
                let recentered = centeredRow(for: normalized)
                if recentered != normalized {
                    suppressSelectionCallback = true
                    pickerView.selectRow(recentered, inComponent: component, animated: false)
                    suppressSelectionCallback = false
                    normalized = recentered
                }
            }

            if parent.selection != normalized {
                parent.selection = normalized
            }
        }
    }
}


private struct InlineTrashTextView: UIViewRepresentable {
    @Binding var text: String
    var onDeleteLine: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITableView {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = true
        tv.keyboardDismissMode = .interactive
        tv.dataSource = context.coordinator
        tv.delegate = context.coordinator
        tv.register(InlineInputRowCell.self, forCellReuseIdentifier: InlineInputRowCell.reuseId)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTableTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        tv.addGestureRecognizer(tap)
        context.coordinator.tableView = tv
        return tv
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.reloadFromTextIfNeeded()
    }

    final class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
        var parent: InlineTrashTextView
        weak var tableView: UITableView?
        private var lines: [String] = []
        private weak var pendingDeleteTextField: UITextField?

        init(_ parent: InlineTrashTextView) {
            self.parent = parent
            self.lines = Self.parse(parent.text)
        }

        private func focusRow(_ row: Int, placeCursorAtEnd: Bool = false) {
            guard let tv = tableView else { return }
            let target = max(0, min(row, max(0, tv.numberOfRows(inSection: 0) - 1)))
            let indexPath = IndexPath(row: target, section: 0)
            tv.scrollToRow(at: indexPath, at: .middle, animated: false)
            DispatchQueue.main.async {
                if let cell = tv.cellForRow(at: indexPath) as? InlineInputRowCell {
                    cell.textField.becomeFirstResponder()
                    if placeCursorAtEnd {
                        let end = cell.textField.endOfDocument
                        cell.textField.selectedTextRange = cell.textField.textRange(from: end, to: end)
                    }
                }
            }
        }

        @objc func handleTableTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = tableView else { return }
            let point = gesture.location(in: tv)
            if let hit = tv.hitTest(point, with: nil), hit is UIControl || hit is UITextField {
                return
            }
            focusRow(lines.count)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if touch.view is UIControl || touch.view is UITextField {
                return false
            }
            return true
        }

        func reloadFromTextIfNeeded() {
            let parsed = Self.parse(parent.text)
            if parsed != lines {
                lines = parsed
                tableView?.reloadData()
            }
        }

        func numberOfSections(in tableView: UITableView) -> Int { 1 }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            lines.count + 1
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            32
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineInputRowCell.reuseId, for: indexPath) as? InlineInputRowCell else {
                return UITableViewCell()
            }

            let isInputRow = indexPath.row >= lines.count
            let rowText = isInputRow ? "" : lines[indexPath.row]

            cell.configure(number: indexPath.row + 1, text: rowText, isPlaceholderRow: isInputRow)
            cell.textField.delegate = self
            cell.textField.tag = indexPath.row
            cell.onDelete = { [weak self] in
                guard let self else { return }
                if self.lines.indices.contains(indexPath.row) {
                    self.parent.onDeleteLine(indexPath.row)
                    self.lines = Self.parse(self.parent.text)
                    self.tableView?.reloadData()
                }
            }
            cell.onTextChanged = { [weak self] newValue in
                self?.updateLine(at: indexPath.row, with: newValue)
            }
            cell.onPaste = { [weak self] pasted in
                self?.applyPastedText(pasted, at: indexPath.row)
            }
            cell.textField.onEmptyBackspace = { [weak self, weak textField = cell.textField] in
                guard let self, let textField else { return }
                guard textField.tag > 0 else { return }

                if self.lines.indices.contains(textField.tag) {
                    self.scheduleDeleteRow(textField.tag, focusTargetRow: textField.tag - 1, deletingTextField: textField)
                } else {
                    self.focusRow(textField.tag - 1, placeCursorAtEnd: true)
                }
            }
            return cell
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return true }
            let next = current.replacingCharacters(in: swiftRange, with: string)

            // Return key (software + physical keyboard) moves to next row.
            if string == "\n" {
                return textFieldShouldReturn(textField)
            }

            // Support mass paste into the table-style input.
            if (string.contains("\n") && string.count > 1) || string.contains(",") {
                applyPastedText(next, at: textField.tag)
                return false
            }

            // If the user presses backspace at the beginning of an empty row,
            // move focus to the previous row and place the cursor at the end.
            if string.isEmpty,
               range.location == 0,
               range.length == 0,
               current.isEmpty,
               textField.tag > 0 {
                focusRow(textField.tag - 1, placeCursorAtEnd: true)
                return false
            }

            // If deleting the final character of a filled row, treat it as the same
            // destructive jump path as an already-empty row backspace.
            if string.isEmpty,
               next.isEmpty,
               !current.isEmpty,
               textField.tag > 0,
               lines.indices.contains(textField.tag) {
                scheduleDeleteRow(textField.tag, focusTargetRow: textField.tag - 1, deletingTextField: textField)
                return false
            }
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let nextRow = textField.tag + 1
            focusRow(nextRow)
            return false
        }

        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            true
        }

        private func scheduleDeleteRow(_ row: Int, focusTargetRow: Int, deletingTextField: UITextField) {
            guard let tv = tableView, lines.indices.contains(row) else { return }

            pendingDeleteTextField = deletingTextField

            let targetRow = max(0, min(focusTargetRow, self.lines.count - 1))
            let targetIndexPath = IndexPath(row: targetRow, section: 0)
            tv.scrollToRow(at: targetIndexPath, at: .middle, animated: false)

            DispatchQueue.main.async {
                guard self.lines.indices.contains(row) else {
                    self.pendingDeleteTextField = nil
                    return
                }

                // Critical: hand first responder directly to the surviving row
                // before collapsing the deleted row, so the keyboard never sees
                // a moment with no active text field.
                if let targetCell = tv.cellForRow(at: targetIndexPath) as? InlineInputRowCell {
                    targetCell.textField.becomeFirstResponder()
                    let end = targetCell.textField.endOfDocument
                    targetCell.textField.selectedTextRange = targetCell.textField.textRange(from: end, to: end)
                }

                DispatchQueue.main.async {
                    guard self.lines.indices.contains(row) else {
                        self.pendingDeleteTextField = nil
                        return
                    }

                    self.lines.remove(at: row)
                    self.writeBack()

                    UIView.performWithoutAnimation {
                        tv.performBatchUpdates {
                            tv.deleteRows(at: [IndexPath(row: row, section: 0)], with: .none)
                        } completion: { _ in
                            let rowCount = tv.numberOfRows(inSection: 0)
                            if rowCount > 0 {
                                let rowsNeedingRefresh = (row..<rowCount).map { IndexPath(row: $0, section: 0) }
                                if !rowsNeedingRefresh.isEmpty {
                                    tv.reloadRows(at: rowsNeedingRefresh, with: .none)
                                }
                            }

                            self.pendingDeleteTextField = nil
                            self.focusRow(focusTargetRow, placeCursorAtEnd: true)
                        }
                    }
                }
            }
        }

        private func applyPastedText(_ text: String, at index: Int) {
            let incoming = Self.parse(text)
            guard !incoming.isEmpty else { return }

            if lines.isEmpty {
                lines = incoming
            } else if lines.indices.contains(index) {
                lines.remove(at: index)
                lines.insert(contentsOf: incoming, at: index)
            } else {
                lines.append(contentsOf: incoming)
            }

            writeBack()
            tableView?.reloadData()
        }

        private func updateLine(at index: Int, with value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

            // Typing in the always-present input row appends a new entry.
            if index == lines.count {
                guard !trimmed.isEmpty else { return }
                lines.append(trimmed)
                writeBack()

                // The current placeholder row has become a real data row.
                // Force its trash visibility/number config before adding next placeholder row.
                if let tv = tableView {
                    let currentRow = IndexPath(row: index, section: 0)
                    if let cell = tv.cellForRow(at: currentRow) as? InlineInputRowCell {
                        cell.configure(number: index + 1, text: trimmed, isPlaceholderRow: false)
                    } else {
                        tv.reloadRows(at: [currentRow], with: .none)
                    }

                    // Insert the new trailing input row without full table reload to avoid keyboard ducking.
                    let newInputRow = IndexPath(row: lines.count, section: 0)
                    if tv.numberOfRows(inSection: 0) == lines.count {
                        tv.performBatchUpdates {
                            tv.insertRows(at: [newInputRow], with: .none)
                        }
                    }
                }
                return
            }

            guard lines.indices.contains(index) else { return }

            if trimmed.isEmpty {
                lines.remove(at: index)
                writeBack()
                tableView?.reloadData()
            } else {
                lines[index] = trimmed
                // Keep typing stable: do not reload rows for every keystroke.
                writeBack()
            }
        }

        private func writeBack() {
            lines = lines
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let formatted = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            parent.text = formatted
        }

        private static func parse(_ text: String) -> [String] {
            let separators = CharacterSet(charactersIn: ",\n")
            return text
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.replacingOccurrences(of: "^[0-9]+[\\.)-]?\\s*", with: "", options: .regularExpression) }
                .filter { !$0.isEmpty }
        }
    }
}

private final class PasteAwareTextField: UITextField {
    var onPasteText: ((String) -> Void)?
    var onEmptyBackspace: (() -> Void)?

    override func paste(_ sender: Any?) {
        if let pasted = UIPasteboard.general.string,
           (pasted.contains("\n") || pasted.contains(",")) {
            onPasteText?(pasted)
            return
        }
        super.paste(sender)
    }

    override func deleteBackward() {
        let cursorAtStart: Bool = {
            guard let selectedTextRange = selectedTextRange else { return false }
            return offset(from: beginningOfDocument, to: selectedTextRange.start) == 0
        }()

        if (text ?? "").isEmpty && cursorAtStart {
            onEmptyBackspace?()
            return
        }

        super.deleteBackward()
    }

}

private final class InlineInputRowCell: UITableViewCell {
    static let reuseId = "InlineInputRowCell"

    let numberLabel = UILabel()
    let textField = PasteAwareTextField()
    let trashButton = UIButton(type: .system)

    var onDelete: (() -> Void)?
    var onTextChanged: ((String) -> Void)?
    var onPaste: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        numberLabel.font = .preferredFont(forTextStyle: .body)
        numberLabel.textColor = UIColor(white: 0.20, alpha: 1.0)
        numberLabel.textAlignment = .right

        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = UIColor(white: 0.08, alpha: 1.0)
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .default
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.onPasteText = { [weak self] pasted in
            self?.onPaste?(pasted)
        }

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        trashButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: config), for: .normal)
        trashButton.tintColor = .systemRed
        trashButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        [numberLabel, textField, trashButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            numberLabel.widthAnchor.constraint(equalToConstant: 28),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 6),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: trashButton.leadingAnchor, constant: -6),

            trashButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            trashButton.widthAnchor.constraint(equalToConstant: 22),
            trashButton.heightAnchor.constraint(equalToConstant: 22),
            trashButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(number: Int, text: String, isPlaceholderRow: Bool) {
        numberLabel.text = "\(number)."
        if isPlaceholderRow {
            textField.attributedPlaceholder = NSAttributedString(
                string: "Type or paste names here…",
                attributes: [.foregroundColor: UIColor(white: 0.35, alpha: 1.0)]
            )
        } else {
            textField.attributedPlaceholder = nil
        }
        textField.text = text
        trashButton.isHidden = isPlaceholderRow
    }

    @objc private func didTapDelete() { onDelete?() }
    @objc private func textChanged() { onTextChanged?(textField.text ?? "") }
}


#Preview {
    ContentView()
}
