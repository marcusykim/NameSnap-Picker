import SwiftUI
import Combine
import UIKit
import AudioToolbox
import AVFoundation

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

    var wheelRepeatCount: Int { 40 }

    var wheelEntries: [NameEntry] {
        let base = availableEntries
        guard !base.isEmpty else { return [] }
        return Array(repeating: base, count: wheelRepeatCount).flatMap { $0 }
    }

    private func nextDrawNumber() -> Int {
        (entries.map(\.drawNumber).max() ?? 0) + 1
    }

    @discardableResult
    func addNamesFromInput() -> Int {
        let separators = CharacterSet(charactersIn: ",\n")
        let names = rawInput
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line in
                line.replacingOccurrences(of: "^[0-9]+[\\.)-]?\\s*", with: "", options: .regularExpression)
            }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else { return 0 }
        var nextNumber = nextDrawNumber()
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
        normalizeWheelIndexIfNeeded(forceCenter: true)
        lastAddedBatch.removeAll()
        return before - entries.count
    }

    func currentWheelEntry() -> NameEntry? {
        let base = availableEntries
        guard !base.isEmpty else { return nil }
        let safe = ((wheelIndex % base.count) + base.count) % base.count
        return base[safe]
    }

    func spinWheelForward(step: Int) {
        let total = wheelEntries.count
        guard total > 0 else { return }
        wheelIndex = (wheelIndex + max(step, 1)) % total
    }

    func normalizeWheelIndexIfNeeded(forceCenter: Bool = false) {
        let baseCount = availableEntries.count
        guard baseCount > 0 else {
            wheelIndex = 0
            return
        }

        let total = baseCount * wheelRepeatCount
        var normalized = wheelIndex
        if normalized < 0 { normalized = ((normalized % total) + total) % total }
        if normalized >= total { normalized = normalized % total }

        let needsRecentering = forceCenter || normalized < baseCount || normalized > (total - baseCount - 1)
        if needsRecentering {
            let midChunk = (wheelRepeatCount / 2) * baseCount
            let offsetInChunk = normalized % baseCount
            wheelIndex = midChunk + offsetInChunk
        } else {
            wheelIndex = normalized
        }
    }

    @discardableResult
    func commitCurrentWheelSelectionAsWinner() -> String? {
        guard let winner = currentWheelEntry() else { return nil }
        return commitWinnerSnapshot(winner)
    }

    @discardableResult
    func commitWinnerSnapshot(_ winner: NameEntry) -> String {
        let display = "\(winner.drawNumber). \(winner.name)"
        history.insert(WinnerRecord(drawNumber: winner.drawNumber, name: winner.name), at: 0)
        if history.count > 20 { history.removeLast() }
        return display
    }

    private func markWinnerAsUsed(_ winner: NameEntry) {
        guard noRepeatMode else { return }
        pickedIds.insert(winner.id)
        if let idx = entries.firstIndex(where: { $0.id == winner.id }) {
            entries[idx].isIncluded = false
        }
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
        normalizeWheelIndexIfNeeded(forceCenter: true)
    }

    func spin() {
        guard !isSpinning else { return }

        if activeEntries.isEmpty {
            selectedName = "Add contestants to start spinning"
            return
        }

        let pool = availableEntries
        if pool.isEmpty {
            selectedName = "All Contestants Picked!"
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
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
            let ticks = Int.random(in: 22...36)
            for i in 0..<ticks {
                let delay = Double(i) * 0.045
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    self.spinWheelForward(step: Int.random(in: 1...3))
                    self.normalizeWheelIndexIfNeeded()
                    self.selectedName = self.currentWheelEntry()?.name ?? ""
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
        history.insert(WinnerRecord(drawNumber: winner.drawNumber, name: winner.name), at: 0)
        if history.count > 20 { history.removeLast() }
        markWinnerAsUsed(winner)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSpinning = false
    }
}

struct ContentView: View {
    @StateObject private var vm = NameSnapViewModel()
    @State private var showCenterAlert = false
    @State private var centerAlertText = ""
    @State private var centerAlertScale: CGFloat = 0.7
    @State private var pulseAddButton = false
    @State private var inputDraftName = ""
    @State private var showClearPoolConfirm = false
    @State private var showResetPoolConfirm = false
    @State private var didShowWinnerForCurrentSpin = false
    @State private var flashIndex = 0
    @State private var showWinnerFlash = false
    @State private var winnerAudioPlayer: AVAudioPlayer?
    @State private var winnerAudioStopWorkItem: DispatchWorkItem?
    @State private var wheelSettleWorkItem: DispatchWorkItem?
    @State private var isWheelSwipeSession = false
    @State private var suppressWheelSettle = false
    @State private var isButtonWheelSpin = false
    @State private var winnerSyncWorkItem: DispatchWorkItem?
    @State private var winnerRemovalWorkItem: DispatchWorkItem?
    @State private var pendingWinnerSnapshot: NameEntry?
    @State private var pendingWinnerDisplay: String = ""

    private let flashColors: [Color] = [.pink, .yellow, .cyan, .green, .orange, .purple]

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
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
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

                ScrollView {
                    VStack(spacing: 16) {
                        Text("NameSnap")
                            .font(titleFont)
                            .foregroundStyle(NSTheme.skyBlue)
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
                                    let added = vm.addNamesFromInput()
                                    guard added > 0 else { return }
                                    showBigAlert("✅ Names Added")
                                    withAnimation(.spring(response: 0.24, dampingFraction: 0.65)) {
                                        pulseAddButton = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                        pulseAddButton = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .font(titleFamilyFont(size: 14))
                                .scaleEffect(pulseAddButton ? 0.96 : 1)

                                Button("Undo Last Add") {
                                    let removed = vm.undoLastAdd()
                                    guard removed > 0 else { return }
                                    showBigAlert("↩️ Undid \(removed)")
                                }
                                .buttonStyle(.bordered)
                                .tint(.orange)
                                .font(titleFamilyFont(size: 13))

                                Button("Clear This List") {
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
                            Toggle("", isOn: $vm.noRepeatMode)
                                .labelsHidden()
                                .tint(.indigo)
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
                                vm.spin()
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
                            .disabled(vm.isSpinning || vm.activeEntries.isEmpty)
                            .opacity(vm.activeEntries.isEmpty ? 0.45 : 1)
                            .padding(.vertical, 6)
                        } else {
                            card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Wheel")
                                        .font(titleFamilyFont(size: 16))
                                    Picker("Wheel", selection: $vm.wheelIndex) {
                                        ForEach(Array(vm.wheelEntries.enumerated()), id: \.offset) { index, item in
                                            Text(item.name).tag(index)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 140)

                                    Button(vm.isSpinning ? "Spinning" : "Spin Wheel") {
                                        isButtonWheelSpin = true
                                        suppressWheelSettle = true
                                        vm.spin()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.indigo)
                                    .font(titleFamilyFont(size: 15))
                                    .disabled(vm.isSpinning || vm.activeEntries.isEmpty)
                                    .opacity(vm.activeEntries.isEmpty ? 0.45 : 1)
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
                    Text(centerAlertText)
                        .font(titleFamilyFont(size: 24))
                        .multilineTextAlignment(.center)
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
                            Text("♻️ Reset this pool?")
                                .font(titleFamilyFont(size: 22))
                                .multilineTextAlignment(.center)

                            Text("This keeps names, but resets inclusion and no-repeat history.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    withAnimation { showResetPoolConfirm = false }
                                }
                                .buttonStyle(.bordered)
                                .font(titleFamilyFont(size: 13))

                                Button("Reset Pool") {
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
                            Text("⚠️ Clear this pool?")
                                .font(titleFamilyFont(size: 22))
                                .multilineTextAlignment(.center)

                            Text("This removes all names from the current pool.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                Button("Cancel") {
                                    withAnimation { showClearPoolConfirm = false }
                                }
                                .buttonStyle(.bordered)
                                .font(titleFamilyFont(size: 13))

                                Button("Clear Pool") {
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
            .overlay(alignment: .bottom) {
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
            .onChange(of: vm.wheelIndex) { _ in
                guard vm.visualMode == .wheel else { return }
                vm.normalizeWheelIndexIfNeeded()
                if let current = vm.currentWheelEntry() {
                    vm.selectedName = current.name
                }
                guard !vm.isSpinning, !isButtonWheelSpin, !suppressWheelSettle else { return }

                // Manual swipe spin: commit winner when wheel settles.
                if !isWheelSwipeSession {
                    isWheelSwipeSession = true
                }

                wheelSettleWorkItem?.cancel()
                let settle = DispatchWorkItem {
                    isWheelSwipeSession = false
                    guard !suppressWheelSettle else { return }
                    guard let winnerName = vm.commitCurrentWheelSelectionAsWinner() else { return }
                    didShowWinnerForCurrentSpin = true
                    triggerWinnerEffects(name: winnerName)
                }
                wheelSettleWorkItem = settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: settle)
            }
            .onChange(of: vm.availableEntries.map(\.id)) { _ in
                suppressWheelSettle = true
                vm.normalizeWheelIndexIfNeeded(forceCenter: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    suppressWheelSettle = false
                }
            }
            .onChange(of: vm.isSpinning) { spinning in
                if spinning {
                    didShowWinnerForCurrentSpin = false
                    isWheelSwipeSession = false
                    wheelSettleWorkItem?.cancel()
                    winnerSyncWorkItem?.cancel()
                    winnerRemovalWorkItem?.cancel()
                    pendingWinnerSnapshot = nil
                    pendingWinnerDisplay = ""
                    suppressWheelSettle = true
                } else {
                    // let wheel settle callbacks quiet down after programmatic spin
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        suppressWheelSettle = false
                        isButtonWheelSpin = false
                    }

                    if !didShowWinnerForCurrentSpin,
                       !vm.selectedName.isEmpty,
                       vm.selectedName != "All Contestants Picked!",
                       vm.selectedName != "Add contestants to start spinning" {
                        didShowWinnerForCurrentSpin = true
                        triggerWinnerEffects(name: vm.selectedName)
                    }
                }
            }
            .preferredColorScheme(.light)
            .navigationBarHidden(true)
        }
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

        init(_ parent: InlineTrashTextView) {
            self.parent = parent
            self.lines = Self.parse(parent.text)
        }

        private func focusRow(_ row: Int) {
            guard let tv = tableView else { return }
            let target = max(0, min(row, max(0, tv.numberOfRows(inSection: 0) - 1)))
            let indexPath = IndexPath(row: target, section: 0)
            tv.scrollToRow(at: indexPath, at: .middle, animated: false)
            DispatchQueue.main.async {
                if let cell = tv.cellForRow(at: indexPath) as? InlineInputRowCell {
                    cell.textField.becomeFirstResponder()
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
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let nextRow = textField.tag + 1
            focusRow(nextRow)
            return false
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

    override func paste(_ sender: Any?) {
        if let pasted = UIPasteboard.general.string,
           (pasted.contains("\n") || pasted.contains(",")) {
            onPasteText?(pasted)
            return
        }
        super.paste(sender)
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
