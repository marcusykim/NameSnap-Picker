import SwiftUI

@main
struct NameSnapApp: App {
    @AppStorage("namesnap.hasCompletedOnboarding.v1") private var hasCompletedOnboarding = false

    private var shouldShowOnboarding: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-onboarding") { return true }
        #endif
        return !hasCompletedOnboarding
    }

    var body: some Scene {
        WindowGroup {
            if shouldShowOnboarding {
                NameSnapOnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                ContentView()
            }
        }
    }
}

private struct NameSnapOnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var page = 0
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? NSTheme.skyBlue : Color.black.opacity(0.14))
                        .frame(height: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(page + 1) of 3")

            Group {
                switch page {
                case 0: fairPickStep
                case 1: repeatStep
                default: cleanStartStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 10) {
                        continueButton
                        if page > 0 { backButton }
                    }
                } else {
                    HStack(spacing: 12) {
                        if page > 0 { backButton }
                        continueButton
                    }
                }
            }
            .padding(20)
            .background(NSTheme.bg)
        }
        .background(NSTheme.bg.ignoresSafeArea())
    }

    private var backButton: some View {
        Button("Back") { move(to: page - 1) }
            .buttonStyle(NameSnapSecondaryButtonStyle())
    }

    private var continueButton: some View {
        Button(page == 2 ? "Build my first list" : "Continue") {
            if page == 2 { onComplete() }
            else { move(to: page + 1) }
        }
        .buttonStyle(NameSnapPrimaryButtonStyle())
        .accessibilityIdentifier("onboardingContinue")
    }

    private var fairPickStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 32)
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(NSTheme.yellow)
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.78))
                }
                .frame(width: 86, height: 86)
                .accessibilityHidden(true)

                Text("A fair pick in seconds.")
                    .font(.system(size: 39, weight: .black, design: .rounded))
                    .tracking(-1.1)
                Text("Paste a class, team, raffle, or party list. NameSnap turns only the names you enter into a clear, satisfying draw.")
                    .font(.title3)
                    .foregroundStyle(Color.black.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
                Label("No account, ads, or tracking", systemImage: "lock.shield.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.15, green: 0.39, blue: 0.28))
            }
            .padding(24)
        }
    }

    private var repeatStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Choose how winners return")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .tracking(-0.9)
                Text("Keep No Repeats on for turn-taking and giveaways. Turn it off when every spin should use the full list.")
                    .font(.title3)
                    .foregroundStyle(Color.black.opacity(0.68))

                VStack(spacing: 0) {
                    settingRow(symbol: "checkmark.circle.fill", title: "No Repeats", detail: "Each winner leaves the active pool", isOn: true)
                    Divider().overlay(Color.black.opacity(0.12))
                    settingRow(symbol: "arrow.triangle.2.circlepath", title: "Reset anytime", detail: "Bring the full list back in one tap", isOn: nil)
                }
                .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.black.opacity(0.1)) }

                Label("Wheel mode always keeps every name available.", systemImage: "circle.hexagongrid.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.68))
            }
            .padding(24)
        }
    }

    private var cleanStartStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Start with your list—nothing else")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .tracking(-0.9)
                Text("Your pool opens empty. Type one name per row, or paste names separated by commas or new lines.")
                    .font(.title3)
                    .foregroundStyle(Color.black.opacity(0.68))

                VStack(alignment: .leading, spacing: 0) {
                    Text("CONTESTANT LIST")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(NSTheme.skyBlue)
                        .padding(.bottom, 12)
                    ForEach(1...4, id: \.self) { row in
                        HStack(spacing: 10) {
                            Text("\(row).")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(Color.black.opacity(0.42))
                                .frame(width: 24, alignment: .trailing)
                            Rectangle()
                                .fill(Color.black.opacity(row == 1 ? 0.16 : 0.08))
                                .frame(height: 2)
                        }
                        .frame(height: 40)
                    }
                }
                .padding(18)
                .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NSTheme.skyBlue.opacity(0.65), lineWidth: 2) }

                Text("Nothing is preloaded, and lists stay on this device for the current session.")
                    .font(.footnote)
                    .foregroundStyle(Color.black.opacity(0.62))
            }
            .padding(24)
        }
    }

    private func settingRow(symbol: String, title: String, detail: String, isOn: Bool?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(NSTheme.skyBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(Color.black.opacity(0.62))
            }
            Spacer()
            if let isOn {
                Toggle("", isOn: .constant(isOn))
                    .labelsHidden()
                    .allowsHitTesting(false)
                    .tint(NSTheme.skyBlue)
            }
        }
        .padding(16)
    }

    private func move(to newPage: Int) {
        if reduceMotion { page = newPage }
        else { withAnimation(.snappy) { page = newPage } }
    }
}

private struct NameSnapPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(NSTheme.skyBlue.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct NameSnapSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.black.opacity(0.72))
            .frame(minWidth: 82, minHeight: 52)
            .background(Color.white.opacity(configuration.isPressed ? 0.55 : 0.82), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color.black.opacity(0.12)) }
    }
}
