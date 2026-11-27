import XCTest

@MainActor
final class InterfaceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        #if compiler(>=6.4)
        if #available(iOS 27.0, *), XCUIDevice.shared.voiceOverService.isEnabled {
            try XCUIDevice.shared.voiceOverService.disable()
            addTeardownBlock { @MainActor in try XCUIDevice.shared.voiceOverService.enable() }
        }
        #endif
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
    }

    private func selectTab(_ name: String) {
        app.tabBars.buttons[name].tap()
    }

    private func result() throws -> XCUIElement {
        let field = app.textViews["tekstWyniku"]
        XCTAssertTrue(field.waitForExistence(timeout: 40), app.debugDescription)
        return field
    }

    func testCzteryKartyIRegulacje() throws {
        XCTAssertEqual(app.tabBars.buttons.count, 4)
        let wheels = app.pickerWheels.allElementsBoundByIndex
        XCTAssertEqual(wheels.map(\.label), ["Wybierz miesiąc", "Wybierz dzień", "Wybierz rok"])
        wheels[0].adjust(toPickerWheelValue: "styczeń")
        wheels[1].adjust(toPickerWheelValue: "31")
        wheels[2].adjust(toPickerWheelValue: "2024")
        wheels[0].adjust(toPickerWheelValue: "luty")
        XCTAssertTrue((wheels[1].value as? String ?? "").hasPrefix("29"))
        wheels[2].adjust(toPickerWheelValue: "2025")
        XCTAssertTrue((wheels[1].value as? String ?? "").hasPrefix("28"))
        for tab in ["Czytaj Biblię", "Losuj cytat", "Wyszukaj", "Liturgia"] {
            selectTab(tab)
            XCTAssertTrue(app.tabBars.buttons[tab].isSelected)
            try app.performAccessibilityAudit { issue in
                print("Audyt \(tab): \(issue.compactDescription) — \(issue.element?.debugDescription ?? "bez elementu")")
                return false
            }
        }
    }

    func testCzytanieIZapisLiturgii() throws {
        app.buttons["Czytaj"].tap()
        let field = try result()
        XCTAssertTrue((field.value as? String ?? "").contains("Źródło: TwojaBiblia.pl"))
        app.navigationBars.buttons["Zapisz do TXT"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "DOCSaveButton").firstMatch.waitForExistence(timeout: 5)
            || app.buttons["Zachowaj"].exists || app.buttons["Zapisz"].exists || app.buttons["Save"].exists, app.debugDescription)
    }

    func testBiblia() throws {
        selectTab("Czytaj Biblię")
        let read = app.buttons["Czytaj"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: read)
        waitForExpectations(timeout: 35)
        read.tap()
        let field = try result()
        XCTAssertTrue((field.value as? String ?? "").contains("Księga Rodzaju"))
    }

    func testLosowanieIPowrot() throws {
        selectTab("Losuj cytat")
        app.scrollViews.buttons["Losuj cytat"].tap()
        _ = try result()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Losuj ponownie"].exists)
        app.buttons["Powrót"].tap()
        XCTAssertTrue(app.sliders["Kategoria cytatu"].exists)
    }

    func testWyszukiwanie() throws {
        selectTab("Wyszukaj")
        let field = app.textFields["Słowa kluczowe"]
        field.tap()
        field.typeText("chleb\n")
        let text = try result()
        XCTAssertTrue((text.value as? String ?? "").contains("Wyniki dla: „chleb” — strona 1"))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Następna strona"].tap()
        let next = try result()
        XCTAssertTrue((next.value as? String ?? "").contains("strona 2"))
    }
}
