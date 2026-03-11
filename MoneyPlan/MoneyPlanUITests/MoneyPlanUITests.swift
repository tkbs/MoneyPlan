//
//  MoneyPlanUITests.swift
//  MoneyPlanUITests
//
//  Created by K N on 2026/03/11.
//

import XCTest

final class MoneyPlanUITests: XCTestCase {
    private enum Scenario: String {
        case empty
        case existingPlan
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddPlanDisplaysInList() throws {
        let app = launchApp(scenario: .empty)

        openPlanList(in: app)
        app.buttons["plan-list-add-button"].tap()

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI追加予定")

        let amountField = app.textFields["金額"]
        amountField.tap()
        amountField.typeText("12000")

        app.buttons["保存"].tap()

        XCTAssertTrue(app.buttons["plan-row-UI追加予定"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testEditAndDeletePlan() throws {
        let app = launchApp(scenario: .existingPlan)

        openDashboard(in: app)

        let existingRow = app.buttons["dashboard-upcoming-plan-row-UI既存予定"]
        XCTAssertTrue(existingRow.waitForExistence(timeout: 2))
        XCTAssertTrue(waitForHittable(existingRow, timeout: 5))
        existingRow.tap()

        let editorTitle = app.navigationBars["予定を編集"]
        XCTAssertTrue(editorTitle.waitForExistence(timeout: 5))

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        replaceText(in: nameField, with: "UI更新予定")

        let amountField = app.textFields["金額"]
        replaceText(in: amountField, with: "45000")

        app.buttons["保存"].tap()

        let updatedRow = app.buttons["dashboard-upcoming-plan-row-UI更新予定"]
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForNonExistence(app.buttons["dashboard-upcoming-plan-row-UI既存予定"], timeout: 5))

        updatedRow.tap()
        app.buttons["削除"].tap()
        app.buttons["削除する"].tap()

        XCTAssertTrue(waitForNonExistence(updatedRow, timeout: 5))
    }

    @MainActor
    func testRecurringPlanCanBeStoppedAndGeneratedPlanDisappears() throws {
        let app = launchApp(scenario: .empty)

        openRecurringPlanList(in: app)
        app.buttons["recurring-plan-list-add-button"].tap()

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI定期家賃")

        let amountField = app.textFields["金額"]
        amountField.tap()
        amountField.typeText("50000")

        app.buttons["保存"].tap()
        XCTAssertTrue(app.buttons["recurring-plan-row-UI定期家賃"].waitForExistence(timeout: 2))

        openPlanList(in: app)
        app.buttons["plan-list-next-month-button"].tap()

        let generatedRow = app.buttons["plan-row-UI定期家賃"]
        XCTAssertTrue(generatedRow.waitForExistence(timeout: 2))

        openRecurringPlanList(in: app)
        app.switches["recurring-plan-toggle-UI定期家賃"].tap()

        openPlanList(in: app)
        XCTAssertTrue(waitForNonExistence(generatedRow, timeout: 2))
    }

    @MainActor
    func testSettingsUpdateReflectsOnDashboard() throws {
        let app = launchApp(scenario: .empty)

        openDashboard(in: app)
        XCTAssertTrue(waitForDashboardBalance("¥100,000", in: app, timeout: 2))

        openSettings(in: app)

        let initialBalanceField = app.textFields["初期残高"]
        XCTAssertTrue(initialBalanceField.waitForExistence(timeout: 2))
        replaceText(in: initialBalanceField, with: "120000")
        app.buttons["保存"].tap()

        tapButtonIfVisible(app.buttons["完了"])
        openDashboard(in: app)
        XCTAssertTrue(waitForDashboardBalance("¥120,000", in: app, timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments += ["-ui-testing"]
            app.launchEnvironment["MONEYPLAN_UI_TEST_SCENARIO"] = Scenario.empty.rawValue
            app.launch()
        }
    }

    /// 指定シナリオでアプリを起動し、タブバー表示まで待つ。
    @MainActor
    private func launchApp(scenario: Scenario) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchEnvironment["MONEYPLAN_UI_TEST_SCENARIO"] = scenario.rawValue
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["ホーム"].waitForExistence(timeout: 2))
        return app
    }

    /// 予定タブを開き、追加ボタンが操作可能になるまで待機する。
    @MainActor
    private func openPlanList(in app: XCUIApplication) {
        app.tabBars.buttons["予定"].tap()
        XCTAssertTrue(waitForHittable(app.buttons["plan-list-add-button"], timeout: 5))
    }

    /// 定期タブを開き、追加ボタンが操作可能になるまで待機する。
    @MainActor
    private func openRecurringPlanList(in app: XCUIApplication) {
        app.tabBars.buttons["定期"].tap()
        XCTAssertTrue(waitForHittable(app.buttons["recurring-plan-list-add-button"], timeout: 5))
    }

    /// 設定タブを開き、初期残高入力欄が操作可能になるまで待機する。
    @MainActor
    private func openSettings(in app: XCUIApplication) {
        app.tabBars.buttons["設定"].tap()
        XCTAssertTrue(waitForHittable(app.textFields["初期残高"], timeout: 5))
    }

    /// ホームタブを開き、現在残高表示が見えるまで待機する。
    @MainActor
    private func openDashboard(in app: XCUIApplication) {
        app.tabBars.buttons["ホーム"].tap()
        XCTAssertTrue(app.staticTexts["dashboard-current-balance-value"].waitForExistence(timeout: 5))
    }

    /// 指定ボタンが表示中ならタップする。
    @MainActor
    private func tapButtonIfVisible(_ button: XCUIElement) {
        guard button.exists else {
            return
        }
        button.tap()
    }

    /// 既存文字列を消してから新しい文字列へ置き換える。
    @MainActor
    private func replaceText(in element: XCUIElement, with newValue: String) {
        element.tap()

        if let currentValue = element.value as? String, currentValue.isEmpty == false {
            let deleteText = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            element.typeText(deleteText)
        }

        element.typeText(newValue)
    }

    /// 要素が非表示になるまで待機する。
    @MainActor
    private func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// 要素がタップ可能になるまで待機する。
    @MainActor
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// 要素ラベルが期待値へ更新されるまで待機する。
    @MainActor
    private func waitForLabel(_ label: String, on element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// ホームの現在残高表示が期待値へ更新されるまで待機する。
    @MainActor
    private func waitForDashboardBalance(_ label: String, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        waitForLabel(label, on: app.staticTexts["dashboard-current-balance-value"], timeout: timeout)
    }
}
