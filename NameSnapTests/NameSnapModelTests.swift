import XCTest
import UIKit
@testable import NameSnap

@MainActor
final class NameSnapModelTests: XCTestCase {
    private func model(_ names: [String] = []) -> NameSnapViewModel {
        let model = NameSnapViewModel()
        model.addNames(names)
        return model
    }

    func testParsesNumberedCommaAndNewlineInput() async {
        let vm = model()
        vm.rawInput = " 1. Alex\r\n2) Zoë, 3- 李雷\n\n Sam O'Neil "
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "Zoë", "李雷", "Sam O'Neil"])
    }

    func testKeepsLeadingDigitsInActualNames() async {
        let vm = model()
        vm.rawInput = "2Pac\n123Alex\n007\n3D Artist\n4.5 Stars"
        XCTAssertEqual(vm.parsedInputNames, ["2Pac", "123Alex", "007", "3D Artist", "4.5 Stars"])
    }

    func testNamesSurviveNumberedEditorRoundTrip() async {
        let vm = model()
        for name in ["2Pac", "Zoë", "李雷", "🧑🏽‍🚀 Sam", "Dr. Lee"] { vm.appendInputName(name) }
        XCTAssertEqual(vm.parsedInputNames, ["2Pac", "Zoë", "李雷", "🧑🏽‍🚀 Sam", "Dr. Lee"])
        vm.updateInputName(at: 1, to: " 007 ")
        XCTAssertEqual(vm.parsedInputNames, ["2Pac", "007", "李雷", "🧑🏽‍🚀 Sam", "Dr. Lee"])
    }

    func testBlankInputDoesNotAddContestants() async {
        let vm = model()
        vm.rawInput = "\n, ,\t"
        XCTAssertEqual(vm.addNamesFromInput(), 0)
        XCTAssertTrue(vm.entries.isEmpty)
    }

    func testInputEditAndDeleteAffectOnlyRequestedRow() async {
        let vm = model()
        vm.rawInput = "Alex\nAlex\nCasey"
        vm.updateInputName(at: 1, to: "Jordan")
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "Jordan", "Casey"])
        vm.removeInputName(at: 1)
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "Casey"])
        vm.updateInputName(at: 0, to: " ")
        XCTAssertEqual(vm.parsedInputNames, ["Casey"])
    }

    func testInvalidInputIndicesAreNoOps() async {
        let vm = model()
        vm.rawInput = "Alex"
        vm.removeInputName(at: -1)
        vm.removeInputName(at: 4)
        vm.updateInputName(at: 2, to: "Jordan")
        XCTAssertEqual(vm.parsedInputNames, ["Alex"])
    }

    func testAddPreservesInputAndCreatesUniqueIdentities() async {
        let vm = model()
        vm.rawInput = "Alex\nAlex\n李雷"
        XCTAssertEqual(vm.addNamesFromInput(), 3)
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "Alex", "李雷"])
        XCTAssertEqual(Set(vm.entries.map(\.id)).count, 3)
        XCTAssertEqual(vm.entries.map(\.drawNumber), [1, 2, 3])
    }

    func testEditingInputDoesNotChangeAlreadyAddedPool() async {
        let vm = model()
        vm.rawInput = "Alex\nCasey"
        vm.addNamesFromInput()
        vm.updateInputName(at: 0, to: "Jordan")
        XCTAssertEqual(vm.entries.map(\.name), ["Alex", "Casey"])
        XCTAssertEqual(vm.parsedInputNames, ["Jordan", "Casey"])
    }

    func testDeletingOneDuplicateKeepsTheOtherIdentity() async {
        let vm = model(["Alex", "Alex", "Casey"])
        let first = vm.entries[0]
        let second = vm.entries[1]
        vm.removeEntry(first)
        XCTAssertEqual(vm.entries.map(\.id), [second.id, vm.entries[1].id])
        XCTAssertEqual(vm.entries.map(\.name), ["Alex", "Casey"])
        XCTAssertEqual(vm.entries.map(\.drawNumber), [1, 2])
    }

    func testAddAfterDeleteKeepsUniqueContiguousNumbers() async {
        let vm = model(["A", "B", "C"])
        vm.removeEntry(vm.entries[1])
        vm.addNames(["D", "E"])
        XCTAssertEqual(vm.entries.map(\.name), ["A", "C", "D", "E"])
        XCTAssertEqual(vm.entries.map(\.drawNumber), [1, 2, 3, 4])
    }

    func testUndoRemovesOnlyLatestSurvivingBatch() async {
        let vm = model(["A", "B"])
        let original = vm.entries.map(\.id)
        vm.rawInput = "Persistent draft"
        vm.addNames(["A", "C"])
        vm.removeEntry(vm.entries[2])
        XCTAssertEqual(vm.undoLastAdd(), 1)
        XCTAssertEqual(vm.entries.map(\.id), original)
        XCTAssertEqual(vm.rawInput, "Persistent draft")
        XCTAssertEqual(vm.undoLastAdd(), 0)
    }

    func testClearInputAndClearPoolAreIndependent() async {
        let vm = model(["A", "B"])
        vm.rawInput = "Draft"
        vm.clearInputList()
        XCTAssertEqual(vm.entries.count, 2)
        vm.rawInput = "Another draft"
        vm.clearThisPool()
        XCTAssertEqual(vm.rawInput, "Another draft")
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertEqual(vm.undoLastAdd(), 0)
        XCTAssertNil(vm.currentWheelEntry())
    }

    func testToggleAffectsOnlyMatchingIdentity() async {
        let vm = model(["Alex", "Alex", "Casey"])
        let second = vm.entries[1]
        vm.toggle(second)
        XCTAssertEqual(vm.availableEntries.map(\.id), [vm.entries[0].id, vm.entries[2].id])
        vm.toggle(second)
        XCTAssertEqual(vm.availableEntries.count, 3)
    }

    func testWinnerConsumesOnlySelectedDuplicate() async {
        let vm = model(["Alex", "Alex", "Casey"])
        let winner = vm.entries[1]
        XCTAssertEqual(vm.commitWinnerSnapshot(winner), "2. Alex")
        XCTAssertEqual(vm.availableEntries.map(\.id), [vm.entries[0].id, vm.entries[2].id])
        XCTAssertEqual(vm.history.first?.displayText, "2. Alex")
        XCTAssertEqual(vm.pickedIds, [winner.id])
    }

    func testRemovedWinnerSnapshotCannotCreateGhostHistory() async {
        let vm = model(["A", "B"])
        let stale = vm.entries[0]
        vm.removeEntry(stale)
        _ = vm.commitWinnerSnapshot(stale)
        XCTAssertTrue(vm.history.isEmpty)
        XCTAssertTrue(vm.pickedIds.isEmpty)
    }

    func testExcludedWinnerCannotBeCommitted() async {
        let vm = model(["A", "B"])
        let excluded = vm.entries[0]
        vm.toggle(excluded)
        _ = vm.commitWinnerSnapshot(excluded)
        XCTAssertTrue(vm.history.isEmpty)
    }

    func testNoRepeatWinnerCannotBeCommittedTwice() async {
        let vm = model(["Alex", "Alex"])
        let winner = vm.entries[0]
        _ = vm.commitWinnerSnapshot(winner)
        _ = vm.commitWinnerSnapshot(winner)
        XCTAssertEqual(vm.history.count, 1)
        XCTAssertEqual(vm.availableEntries.count, 1)
    }

    func testRepeatModeKeepsContestantsEligible() async {
        let vm = model(["Alex"])
        vm.noRepeatMode = false
        for _ in 0..<3 { _ = vm.commitWinnerSnapshot(vm.entries[0]) }
        XCTAssertEqual(vm.history.count, 3)
        XCTAssertEqual(vm.availableEntries.count, 1)
        XCTAssertTrue(vm.pickedIds.isEmpty)
    }

    func testResetRestoresAllContestantsAndClearsHistory() async {
        let vm = model(["A", "B", "C"])
        let ids = vm.entries.map(\.id)
        _ = vm.commitWinnerSnapshot(vm.entries[0])
        vm.toggle(vm.entries[1])
        vm.resetThisPool()
        XCTAssertEqual(vm.availableEntries.map(\.id), ids)
        XCTAssertTrue(vm.pickedIds.isEmpty)
        XCTAssertTrue(vm.history.isEmpty)
        XCTAssertEqual(vm.selectedName, "")
    }

    func testWheelRowsWrapAndRecenterWithoutChangingIdentity() async {
        let vm = model(["A", "B", "C"])
        for row in [-100001, -1, 0, 1, 49999, 50000, 200005] {
            let expected = vm.entries[((row % 3) + 3) % 3]
            XCTAssertEqual(vm.wheelEntry(at: row)?.id, expected.id)
        }
        for row in [0, 1, 2, 25000, 49999] {
            vm.wheelIndex = row
            let id = vm.currentWheelEntry()?.id
            vm.normalizeWheelIndexIfNeeded(forceCenter: true)
            XCTAssertEqual(vm.currentWheelEntry()?.id, id)
        }
    }

    func testWheelNeverReturnsConsumedOrExcludedContestants() async {
        let vm = model(["A", "B", "C"])
        let remaining = vm.entries[2]
        _ = vm.commitWinnerSnapshot(vm.entries[0])
        vm.toggle(vm.entries[1])
        for row in 0..<100 { XCTAssertEqual(vm.wheelEntry(at: row)?.id, remaining.id) }
    }

    func testHistoryPreservesActualPickAfterPoolRenumbering() async {
        let vm = model(["A", "B", "C"])
        _ = vm.commitWinnerSnapshot(vm.entries[2])
        vm.removeEntry(vm.entries[0])
        XCTAssertEqual(vm.history.first?.displayText, "3. C")
        XCTAssertEqual(vm.entries.last?.drawNumber, 2)
    }

    func testHistoryIsBoundedAndNewestFirst() async {
        let vm = model((1...25).map { "Person \($0)" })
        for entry in vm.entries { _ = vm.commitWinnerSnapshot(entry) }
        XCTAssertEqual(vm.history.count, 20)
        XCTAssertEqual(vm.history.first?.displayText, "25. Person 25")
        XCTAssertEqual(vm.history.last?.displayText, "6. Person 6")
        XCTAssertTrue(vm.availableEntries.isEmpty)
    }

    func testClearDuringSpinCancelsPendingWinner() async throws {
        let vm = model(["A", "B"])
        vm.spin()
        vm.clearThisPool()
        try await Task.sleep(for: .seconds(1.7))
        XCTAssertFalse(vm.isSpinning)
        XCTAssertEqual(vm.selectedName, "")
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertTrue(vm.history.isEmpty)
    }

    func testDeleteDuringSpinCannotSelectDeletedContestant() async throws {
        let vm = model(["Only contestant"])
        vm.spin()
        vm.removeEntry(vm.entries[0])
        try await Task.sleep(for: .seconds(1.7))
        XCTAssertFalse(vm.isSpinning)
        XCTAssertEqual(vm.selectedName, "")
        XCTAssertTrue(vm.availableEntries.isEmpty)
    }

    func testClassicSpinWinnerMatchesARealEligibleNameAndNumber() async throws {
        let vm = model(["2Pac", "Alex", "Alex", "李雷"])
        vm.toggle(vm.entries[0])
        vm.spin()
        try await Task.sleep(for: .seconds(1.7))
        XCTAssertFalse(vm.isSpinning)
        XCTAssertTrue(vm.availableEntries.contains { "\($0.drawNumber). \($0.name)" == vm.selectedName })
        vm.commitSelectedNameAsWinnerIfNeeded()
        XCTAssertEqual(vm.history.first?.displayText, vm.selectedName)
        XCTAssertEqual(vm.availableEntries.count, 2)
    }

    func testBlankDirectAddsAreFiltered() async {
        let vm = model([" ", " 2Pac ", "", "李雷"])
        XCTAssertEqual(vm.entries.map(\.name), ["2Pac", "李雷"])
    }

    func testEmptyEligiblePoolDoesNotWarnAboutHistoricalDuplicates() async {
        let vm = model(["Alex"])
        _ = vm.commitWinnerSnapshot(vm.entries[0])
        XCTAssertEqual(vm.poolDuplicateCount(in: ["Alex", "Alex"]), 0)
        XCTAssertEqual(vm.namesExcludingPoolDuplicates(["Alex", "Alex"]), ["Alex", "Alex"])
    }

    func testDuplicateChoicesUseEligibleNamesAndPreserveOriginalSpelling() async {
        let vm = model(["Zoë", "Removed"])
        vm.toggle(vm.entries[1])
        let names = [" zoe ", "Removed", "李雷", "李雷"]
        XCTAssertEqual(vm.poolDuplicateCount(in: names), 2)
        XCTAssertEqual(vm.namesExcludingPoolDuplicates(names), ["Removed", "李雷"])
    }

    func testSnapshotUsesCurrentNumberForSameIdentity() async {
        let vm = model(["A", "Alex", "Alex"])
        let snapshot = vm.entries[2]
        vm.removeEntry(vm.entries[0])
        XCTAssertEqual(vm.commitWinnerSnapshot(snapshot), "2. Alex")
        XCTAssertEqual(vm.pickedIds, [snapshot.id])
    }

    func testRecenterPreservesIdentityEvenForOutOfRangeRows() async {
        let vm = model(["A", "B", "C"])
        for row in [-100001, -1, 50000, 200005] {
            vm.wheelIndex = row
            let id = vm.currentWheelEntry()?.id
            vm.normalizeWheelIndexIfNeeded(forceCenter: true)
            XCTAssertEqual(vm.currentWheelEntry()?.id, id)
        }
    }

    func testPoolMutationsCancelEverySpinMode() async throws {
        var models: [NameSnapViewModel] = []
        for mode in SpinVisualMode.allCases {
            for action in 0..<5 {
                let vm = model(["A", "B"])
                vm.visualMode = mode
                vm.spin()
                switch action {
                case 0: vm.resetThisPool()
                case 1: vm.toggle(vm.entries[0])
                case 2: vm.addNames(["C"])
                case 3: vm.undoLastAdd()
                default: vm.visualMode = mode == .classic ? .wheel : .classic
                }
                models.append(vm)
            }
        }
        try await Task.sleep(for: .seconds(3.8))
        for vm in models {
            XCTAssertFalse(vm.isSpinning)
            XCTAssertEqual(vm.selectedName, "")
            XCTAssertNil(vm.commitSelectedNameAsWinnerIfNeeded())
            XCTAssertTrue(vm.history.isEmpty)
        }
    }

    func testWheelSpinCommitsExactlyItsDisplayedEligibleContestant() async throws {
        let vm = model(["007", "Alex", "Alex", "Dr. Lee", "🧑🏽‍🚀 Sam"])
        vm.visualMode = .wheel
        vm.toggle(vm.entries[0])
        vm.spin()
        try await Task.sleep(for: .seconds(3.8))
        XCTAssertFalse(vm.isSpinning)
        let displayed = vm.selectedName
        let highlighted = vm.currentWheelEntry()
        XCTAssertEqual(displayed, highlighted.map { "\($0.drawNumber). \($0.name)" })
        XCTAssertEqual(vm.commitSelectedNameAsWinnerIfNeeded(), displayed)
        XCTAssertEqual(vm.history.first?.displayText, displayed)
        XCTAssertEqual(vm.pickedIds, Set([highlighted!.id]))
        XCTAssertNil(vm.commitSelectedNameAsWinnerIfNeeded())
        XCTAssertEqual(vm.history.count, 1)
    }

    func testAllIndividualNamesCanBeConsumedOnceAcrossLargePool() async {
        let vm = model((0..<500).map { "Contestant \($0 % 17)" })
        let initial = vm.entries
        for entry in initial.reversed() {
            XCTAssertEqual(vm.commitWinnerSnapshot(entry), "\(entry.drawNumber). \(entry.name)")
        }
        XCTAssertEqual(vm.pickedIds, Set(initial.map(\.id)))
        XCTAssertTrue(vm.availableEntries.isEmpty)
        XCTAssertNil(vm.commitCurrentWheelSelectionAsWinner())
        vm.resetThisPool()
        XCTAssertEqual(vm.availableEntries.map(\.id), initial.map(\.id))
    }
}

@MainActor
final class NameSnapInputEditorTests: XCTestCase {
    private func editor(_ input: String) -> (NameSnapViewModel, InlineTrashTextView.Coordinator, UITableView) {
        let vm = NameSnapViewModel()
        vm.rawInput = input
        let editor = InlineTrashTextView(text: .init(get: { vm.rawInput }, set: { vm.rawInput = $0 }), onDeleteLine: { vm.removeInputName(at: $0) })
        let coordinator = editor.makeCoordinator()
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 350, height: 300))
        table.register(InlineInputRowCell.self, forCellReuseIdentifier: InlineInputRowCell.reuseId)
        table.dataSource = coordinator
        table.delegate = coordinator
        coordinator.tableView = table
        table.reloadData()
        table.layoutIfNeeded()
        return (vm, coordinator, table)
    }

    private func cell(_ row: Int, _ coordinator: InlineTrashTextView.Coordinator, _ table: UITableView) -> InlineInputRowCell {
        table.layoutIfNeeded()
        return table.cellForRow(at: IndexPath(row: row, section: 0)) as! InlineInputRowCell
    }

    func testEditorKeepsNumericAndUnicodeNames() async {
        let (_, coordinator, table) = editor("2Pac\n007\n李雷\n🧑🏽‍🚀 Sam")
        XCTAssertEqual(coordinator.tableView(table, numberOfRowsInSection: 0), 5)
        XCTAssertEqual((0..<4).map { cell($0, coordinator, table).textField.text! }, ["2Pac", "007", "李雷", "🧑🏽‍🚀 Sam"])
        XCTAssertTrue(cell(4, coordinator, table).trashButton.isHidden)
    }

    func testEditingSecondDuplicateChangesOnlyThatInputRow() async {
        let (vm, coordinator, table) = editor("Alex\nAlex\nCasey")
        cell(1, coordinator, table).onTextChanged?("007")
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "007", "Casey"])
    }

    func testTrashDeletesOnlyRequestedRowAndRenumbersRemainingRows() async {
        let (vm, coordinator, table) = editor("A\nB\nC")
        cell(1, coordinator, table).onDelete?()
        XCTAssertEqual(vm.parsedInputNames, ["A", "C"])
        XCTAssertEqual(cell(1, coordinator, table).numberLabel.text, "2.")
        XCTAssertEqual(cell(1, coordinator, table).textField.text, "C")
        cell(0, coordinator, table).onDelete?()
        cell(0, coordinator, table).onDelete?()
        XCTAssertTrue(vm.parsedInputNames.isEmpty)
        XCTAssertEqual(coordinator.tableView(table, numberOfRowsInSection: 0), 1)
    }

    func testMultilinePastePreservesUnselectedPrefixAndSuffix() async {
        let (vm, coordinator, table) = editor("Alex Jr\nCasey")
        let field = cell(0, coordinator, table).textField
        XCTAssertFalse(coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 4, length: 0), replacementString: "\n007\nSam"))
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "007", "Sam Jr", "Casey"])
    }

    func testMultilinePasteReplacesOnlySelectedUnicodeText() async {
        let (vm, coordinator, table) = editor("🧑🏽‍🚀 Sam\nCasey")
        let field = cell(0, coordinator, table).textField
        XCTAssertFalse(coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: ("🧑🏽‍🚀 Sam" as NSString).length), replacementString: "Zoë,李雷"))
        XCTAssertEqual(vm.parsedInputNames, ["Zoë", "李雷", "Casey"])
    }

    func testTypingTrailingRowAddsOneNameAndKeepsEmptyInputRow() async {
        let (vm, coordinator, table) = editor("Alex")
        cell(1, coordinator, table).onTextChanged?("2Pac")
        XCTAssertEqual(vm.parsedInputNames, ["Alex", "2Pac"])
        XCTAssertEqual(coordinator.tableView(table, numberOfRowsInSection: 0), 3)
        XCTAssertTrue(cell(2, coordinator, table).trashButton.isHidden)
    }

    func testClearingFirstRowKeepsKeyboardFocusForReplacement() async throws {
        let (vm, coordinator, table) = editor("Alex")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let controller = UIViewController()
        window.rootViewController = controller
        controller.view.addSubview(table)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let first = cell(0, coordinator, table)
        first.textField.becomeFirstResponder()
        first.onTextChanged?("")
        try await Task.sleep(for: .milliseconds(100))
        let replacement = cell(0, coordinator, table)
        XCTAssertTrue(replacement.textField.isFirstResponder)
        replacement.onTextChanged?("Jordan")
        XCTAssertEqual(vm.parsedInputNames, ["Jordan"])
    }

}
