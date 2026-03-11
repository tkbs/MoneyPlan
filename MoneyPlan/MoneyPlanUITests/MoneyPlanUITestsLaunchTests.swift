//
//  MoneyPlanUITestsLaunchTests.swift
//  MoneyPlanUITests
//
//  Created by K N on 2026/03/11.
//

import XCTest

final class MoneyPlanUITestsLaunchTests: XCTestCase {
    private enum Scenario: String {
        case empty
    }

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = makeLaunchTestApp()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["ホーム"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// 起動テスト用の初期化済みアプリを返す。
    @MainActor
    private func makeLaunchTestApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launchEnvironment["MONEYPLAN_UI_TEST_SCENARIO"] = Scenario.empty.rawValue
        return app
    }
}
