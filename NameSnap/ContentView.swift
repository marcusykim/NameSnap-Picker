import SwiftUI
import Combine
import UIKit

struct NameEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isIncluded: Bool

    init(id: UUID = UUID(), name: String, isIncluded: Bool = true) {
        self.id = id
        self.name = name
        self.isIncluded = isIncluded
    }
}

enum NSTheme {
    static let bg = Color(red: 224 / 255, green: 244 / 255, blue: 171 / 255)
    static let skyBlue = Color(red: 107 / 255, green: 163 / 255, blue: 204 / 255)
    static let tan = Color(red: 199 / 255, green: 171 / 255, blue: 138 / 255)
    static let card = Color(red: 242 / 255, green: 244 / 255, blue: 250 / 255)
    static let yellow = Color(red: 247 / 255, green: 220 / 255, blue: 96 / 255)
}

@MainActor
final class NameSnapViewModel: ObservableObject {
    @Published var rawInput: String = ""
    @Published var entries: [NameEntry] = []
    @Published var selectedName: String = ""
    @Published var isSpinning = false
    @Published var noRepeatMode = true
    @Published var pickedIds: Set<UUID> = []
    @Published var history: [String] = []

    var activeEntries: [NameEntry] { entries.filter { $0.isIncluded } }

    var availableEntries: [NameEntry] {
        if !noRepeatMode { return activeEntries }
        return activeEntries.filter { !pickedIds.contains($0.id) }
    }

    func addNamesFromInput() {
        let separators = CharacterSet(charactersIn: ",\n")
        let names = rawInput
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !names.isEmpty else { return }
        let newOnes = names.map { NameEntry(name: $0) }
        entries.append(contentsOf: newOnes)
        pickedIds = pickedIds.intersection(Set(entries.map { $0.id }))
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
    }

    func clearThisPool() {
        entries.removeAll()
        pickedIds.removeAll()
        selectedName = ""
        history.removeAll()
    }

    func removeEntry(_ entry: NameEntry) {
        entries.removeAll { $0.id == entry.id }
        pickedIds.remove(entry.id)
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
    }

    private func finishSpin(pool: [NameEntry]) {
        guard let winner = pool.randomElement() else { isSpinning = false; return }
        selectedName = winner.name
        history.insert(winner.name, at: 0)
        if history.count > 20 { history.removeLast() }
        if noRepeatMode { pickedIds.insert(winner.id) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSpinning = false
    }
}

struct ContentView: View {
    @StateObject private var vm = NameSnapViewModel()

    private var titleFont: Font {
        if UIFont(name: "RubikMonoOne-Regular", size: 38) != nil {
            return .custom("RubikMonoOne-Regular", size: 38)
        }
        if UIFont(name: "Rubik Mono One", size: 38) != nil {
            return .custom("Rubik Mono One", size: 38)
        }
        return .system(size: 38, weight: .black, design: .rounded)
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

                                    if vm.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("Type or paste names here…")
                                            .foregroundStyle(.secondary)
                                            .padding(.top, 16)
                                            .padding(.leading, 14)
                                    }

                                    TextEditor(text: $vm.rawInput)
                                        .frame(height: 120)
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .background(Color.clear)
                                }

                                Button("Add These Names to Pool") { vm.addNamesFromInput() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.indigo)

                                Button("Clear This List") { vm.clearInputList() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
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
                                    .font(.system(size: 34, weight: .black, design: .rounded))
                                    .foregroundStyle(NSTheme.skyBlue)
                            }
                        }
                        .disabled(vm.isSpinning || vm.activeEntries.isEmpty)
                        .opacity(vm.activeEntries.isEmpty ? 0.45 : 1)
                        .padding(.vertical, 6)

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
                                    ForEach(vm.history, id: \.self) { item in
                                        Text("• \(item)")
                                    }
                                }
                            }
                        }

                        if !vm.entries.isEmpty {
                            card {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pool")
                                        .font(.headline)
                                    ForEach(vm.entries) { entry in
                                        HStack(spacing: 10) {
                                            Button {
                                                vm.toggle(entry)
                                            } label: {
                                                HStack(spacing: 10) {
                                                    Image(systemName: entry.isIncluded ? "checkmark.circle.fill" : "circle")
                                                        .foregroundStyle(entry.isIncluded ? Color.indigo : Color.secondary)
                                                    Text(entry.name)
                                                        .foregroundStyle(.primary)
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
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button("Reset This Pool") { vm.resetThisPool() }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    Button("Clear This Pool") { vm.clearThisPool() }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(NSTheme.bg)
            }
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

#Preview {
    ContentView()
}
