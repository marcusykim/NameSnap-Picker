import SwiftUI
import Combine
import UIKit
import AudioToolbox
import AVFoundation
import StoreKit

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

enum NSTheme {
    static let bg = Color(red: 224 / 255, green: 244 / 255, blue: 171 / 255)
    static let skyBlue = Color(red: 107 / 255, green: 163 / 255, blue: 204 / 255)
    static let tan = Color(red: 199 / 255, green: 171 / 255, blue: 138 / 255)
    static let card = Color(red: 242 / 255, green: 244 / 255, blue: 250 / 255)
    static let yellow = Color(red: 247 / 255, green: 220 / 255, blue: 96 / 255)
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
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
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
        if let assetName = emojiAssetName(for: symbol) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size + 8, height: size + 8)
                .accessibilityLabel(emojiAccessibilityLabel(for: symbol))
        } else {
            Text(verbatim: symbol)
                .font(.system(size: size))
        }
    }

    private func emojiAssetName(for symbol: String) -> String? {
        if symbol.contains("✅") || symbol.contains("✔") { return "success_emoji" }
        if symbol.contains("🎉") { return "party_popper_emoji" }
        if symbol.contains("✨") { return "sparkle_emoji" }
        if symbol.contains("↩") { return "undo_emoji" }
        if symbol.contains("🧹") { return "broom_emoji" }
        if symbol.contains("⚠") { return "warning_emoji" }
        if symbol.contains("♻") { return "recycle_emoji" }
        if symbol.contains("🔈") { return "sound_emoji" }
        if symbol.contains("🔁") { return "repeat_emoji" }
        return nil
    }

    private func emojiAccessibilityLabel(for symbol: String) -> String {
        if symbol.contains("✅") || symbol.contains("✔") { return "Success" }
        if symbol.contains("🎉") { return "Winner" }
        if symbol.contains("✨") { return "Upgrade" }
        if symbol.contains("↩") { return "Undo" }
        if symbol.contains("🧹") { return "Cleared" }
        if symbol.contains("⚠") { return "Warning" }
        if symbol.contains("♻") { return "Reset" }
        if symbol.contains("🔈") { return "Sound" }
        if symbol.contains("🔁") { return "Repeat" }
        return "Status"
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

    private func shouldPresentPaywall(currentCount: Int, incomingCount: Int) -> Bool {
        guard incomingCount > 0 else { return false }
        guard (currentCount + incomingCount) > freeContestantLimit else { return false }
        if !purchases.isUnlimitedUnlocked { return true }
        return purchases.isTestStoreEnvironment
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
            withAnimation(.easeInOut(duration: 0.25)) {
                showCenterAlert = false
            }
        }
    }


    private func triggerWinnerEffects(name: String) {
        showBigAlert("🎉 Winner: \(name)")
        playCelebrationSoundReliably()
        showWinnerFlash = true
        flashIndex = 0

        for step in 0..<10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(step) * 0.08)) {
                flashIndex = step % flashColors.count
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.2)) {
                showWinnerFlash = false
            }
        }
    }

    private func playCelebrationSoundReliably() {
        playRandomCelebrationSound()

        // Rare simulator/audio-session race: retry once if playback did not start.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            if winnerAudioPlayer?.isPlaying != true {
                playRandomCelebrationSound()
            }
        }
    }

    private func playRandomCelebrationSound() {
        // Preferred: bundled techno winner clips.
        let customNames = [
            "techno_upbeat_01",
            "techno_upbeat_02",
            "techno_upbeat_03",
            "techno_upbeat_04",
            "techno_upbeat_alt_01",
            "techno_upbeat_alt_02",
            "techno_upbeat_alt_03",
            "techno_upbeat_alt_04",
            "techno_upbeat_alt_05",
            "techno_upbeat_alt_06"
        ]
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

        var availableURLs: [URL] = []
        for name in customNames {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    availableURLs.append(url)
                }
            }
        }

        guard !availableURLs.isEmpty else {
            print("No bundled winner audio files found in app bundle.")
            return
        }

        for url in availableURLs.shuffled() {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.currentTime = 0
                player.numberOfLoops = 0
                player.volume = 1.0

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.8, execute: stopItem)
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
                NSTheme.bg
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }

                ScrollView {
                    VStack(spacing: 16) {
                        Text("NameSnap")
                            .font(titleFont)
                            .foregroundStyle(NSTheme.skyBlue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Contestant List")
                                    .font(.headline)

                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(NSTheme.skyBlue.opacity(0.8), lineWidth: 2)
                                        )

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

                                Button("Add These Names to Pool") {
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
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .font(titleFamilyFont(size: 14))
                                .scaleEffect(pulseAddButton ? 0.96 : 1)

                                Button("Undo Last Add") {
                                    dismissKeyboard()
                                    let removed = vm.undoLastAdd()
                                    guard removed > 0 else { return }
                                    showBigAlert("↩️ Undid \(removed)")
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                                .font(titleFamilyFont(size: 13))

                                Button("Clear This List") {
                                    dismissKeyboard()
                                    vm.clearInputList()
                                    showBigAlert("🧹 List Cleared")
                                }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    .font(titleFamilyFont(size: 13))

                                HStack {
                                    Spacer()
                                    Text("Input total: \(vm.parsedInputNames.count)")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Text("No repeats until reset")
                                .font(.body.weight(.medium))
                            Toggle("", isOn: $noRepeatToggleUIValue)
                                .labelsHidden()
                                .tint(.indigo)
                                .onChange(of: noRepeatToggleUIValue) { newValue in
                                    guard !suppressNoRepeatToggleConfirm else { return }
                                    pendingNoRepeatValue = newValue
                                    withAnimation { showNoRepeatToggleConfirm = true }
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        Picker("Spin Mode", selection: $vm.visualMode) {
                            ForEach(SpinVisualMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

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
                                        .fill(NSTheme.tan)
                                        .frame(width: 250, height: 250)
                                        .opacity(0.55)

                                    Circle()
                                        .fill(NSTheme.yellow)
                                        .frame(width: 160, height: 160)
                                        .shadow(color: NSTheme.yellow.opacity(0.5), radius: 10, y: 4)

                                    Text(vm.isSpinning ? "Spinning" : "Spin")
                                        .font(titleFamilyFont(size: 32))
                                        .foregroundStyle(NSTheme.skyBlue)
                                }
                            }
                            .disabled(vm.isSpinning || vm.entries.isEmpty)
                            .opacity(vm.entries.isEmpty ? 0.45 : 1)
                            .padding(.vertical, 6)
                        } else {
                            card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Wheel")
                                        .font(titleFamilyFont(size: 16))
                                    if vm.wheelVirtualRowCount == 0 {
                                        Text("No available contestants")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, minHeight: 140)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        InfiniteWheelPicker(
                                            entries: vm.wheelBaseEntries,
                                            selection: $vm.wheelIndex,
                                            rowCount: vm.wheelVirtualRowCount,
                                            animateProgrammaticChanges: vm.isSpinning
                                        )
                                        .frame(height: 140)
                                    }

                                    Button(vm.isSpinning ? "Spinning" : "Spin Wheel") {
                                        dismissKeyboard()
                                        if vm.activeEntries.isEmpty && !vm.entries.isEmpty {
                                            showBigAlert("⚠️ All winners have been selected")
                                        } else {
                                            isButtonWheelSpin = true
                                            suppressWheelSettle = true
                                            vm.spin()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.indigo)
                                    .font(titleFamilyFont(size: 15))
                                    .disabled(vm.isSpinning || vm.entries.isEmpty)
                                    .opacity(vm.entries.isEmpty ? 0.45 : 1)
                                }
                            }
                        }

                        if !vm.selectedName.isEmpty {
                            Text(vm.selectedName)
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [NSTheme.yellow.opacity(0.4), Color.orange.opacity(0.18)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        if !vm.history.isEmpty {
                            card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recent winners")
                                        .font(.headline)
                                    ForEach(vm.history) { item in
                                        Text("• \(item.displayText)")
                                    }
                                }
                            }
                        }

                        if !vm.entries.isEmpty {
                            card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pool")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .foregroundColor(.black)
                                    ForEach(vm.poolEntriesForDisplay) { entry in
                                        HStack(spacing: 10) {
                                            Button {
                                                vm.toggle(entry)
                                            } label: {
                                                HStack(spacing: 10) {
                                                    Image(systemName: entry.isIncluded ? "checkmark.circle.fill" : "circle")
                                                        .foregroundStyle(entry.isIncluded ? Color.indigo : Color.gray)
                                                    Text("\(entry.drawNumber). \(entry.name)")
                                                        .foregroundColor(.black)
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
                                    }

                                    HStack {
                                        Spacer()
                                        Text("Pool total: \(vm.poolEntriesForDisplay.count)")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 12)
                    }
                    .padding()
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
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .scaleEffect(centerAlertScale)
                        .transition(.scale.combined(with: .opacity))
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
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    withAnimation { showResetPoolConfirm = false }
                                }
                                .buttonStyle(.bordered)
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
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                    }
                    .transition(.opacity)
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
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    dismissKeyboard()
                                    withAnimation { showClearPoolConfirm = false }
                                }
                                .buttonStyle(.bordered)
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
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                    }
                    .transition(.opacity)
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
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            .font(titleFamilyFont(size: 13))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                    }
                    .transition(.opacity)
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
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Skip duplicates") {
                                    let namesToAdd = namesExcludingPoolDuplicates(pendingDuplicateInputNames)
                                    pendingDuplicateInputNames.removeAll()
                                    withAnimation { showDuplicateConfirm = false }
                                    beginAddingNames(namesToAdd)
                                }
                                .buttonStyle(.bordered)
                                .font(titleFamilyFont(size: 13))

                                Button("Add all anyway") {
                                    let namesToAdd = pendingDuplicateInputNames
                                    pendingDuplicateInputNames.removeAll()
                                    withAnimation { showDuplicateConfirm = false }
                                    beginAddingNames(namesToAdd)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                    }
                    .transition(.opacity)
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
                                        .buttonStyle(.bordered)
                                        .font(titleFamilyFont(size: 13))
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Button("Not Now") {
                                            dismissKeyboard()
                                            pendingNamesForAddition.removeAll()
                                            withAnimation { showUpgradeConfirm = false }
                                        }
                                        .buttonStyle(.bordered)
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
                            .buttonStyle(.bordered)
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
                            .tint(.indigo)
                            .padding(.vertical, 10)
                            .accessibilityElement(children: .contain)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                        .frame(height: dynamicTypeSize.isAccessibilitySize ? UIScreen.main.bounds.height * 0.88 : 480)
                        .background(Color(red: 0.96, green: 0.97, blue: 0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                    }
                    .transition(.opacity)
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
                                .foregroundStyle(.secondary)
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
                                .buttonStyle(.bordered)
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
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .font(titleFamilyFont(size: 13))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.65), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 12)
                        .padding(.horizontal, 22)
                    }
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .bottom) {
                if !showUpgradeConfirm && !vm.entries.isEmpty {
                    VStack(spacing: 10) {
                        Button("Reset This Pool") { showResetPoolConfirm = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            .font(titleFamilyFont(size: 14))
                        Button("Clear This Pool") { showClearPoolConfirm = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .font(titleFamilyFont(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(NSTheme.bg)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .onChange(of: vm.wheelIndex) { _ in
                guard vm.visualMode == .wheel else { return }
                vm.normalizeWheelIndexIfNeeded()

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
            .onAppear {
                noRepeatToggleUIValue = vm.noRepeatMode
                pendingNoRepeatValue = vm.noRepeatMode
                runLaunchSilentModeCheckIfNeeded()
                if shouldTriggerThresholdPaywallForUITesting && !didRunThresholdPaywallCheck {
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
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NSTheme.skyBlue.opacity(0.12), lineWidth: 1)
            )
    }
}


private struct InfiniteWheelPicker: UIViewRepresentable {
    let entries: [NameEntry]
    @Binding var selection: Int
    let rowCount: Int
    let animateProgrammaticChanges: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
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

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            guard baseCount > 0 else { return nil }
            let entry = parent.entries[wrappedModulo(row, modulus: baseCount)]
            return "\(entry.drawNumber). \(entry.name)"
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
