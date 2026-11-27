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

    func testPiecKartIRegulacje() throws {
        XCTAssertEqual(app.tabBars.buttons.count, 5)
        let wheels = app.pickerWheels.allElementsBoundByIndex
        XCTAssertEqual(wheels.map(\.label), ["Wybierz miesiąc", "Wybierz dzień", "Wybierz rok"])
        wheels[0].adjust(toPickerWheelValue: "styczeń")
        wheels[1].adjust(toPickerWheelValue: "31")
        wheels[2].adjust(toPickerWheelValue: "2024")
        wheels[0].adjust(toPickerWheelValue: "luty")
        XCTAssertTrue((wheels[1].value as? String ?? "").hasPrefix("29"))
        wheels[2].adjust(toPickerWheelValue: "2025")
        XCTAssertTrue((wheels[1].value as? String ?? "").hasPrefix("28"))
        for tab in ["Czytaj Biblię", "Losuj cytat", "Wyszukaj", "Ustawienia", "Liturgia"] {
            selectTab(tab)
            XCTAssertTrue(app.tabBars.buttons[tab].isSelected)
            try app.performAccessibilityAudit { issue in
                print("Audyt \(tab): \(issue.compactDescription) — \(issue.element?.debugDescription ?? "bez elementu")")
                return false
            }
        }
    }

    private func checkPlayback() {
        app.buttons["Czytaj na głos"].tap()
        let pause = app.buttons["Wstrzymaj czytanie"]
        XCTAssertTrue(pause.waitForExistence(timeout: 6))
        pause.tap()
        app.buttons["Wznów czytanie"].tap()
        app.buttons["Czytaj od początku"].tap()
        app.buttons["Zatrzymaj czytanie"].tap()
        XCTAssertTrue(app.buttons["Czytaj na głos"].exists)
    }

    func testMowaPsalmu() throws {
        let part = app.sliders["Część liturgii"]
        part.adjust(toNormalizedSliderPosition: 0.6)
        XCTAssertEqual(part.value as? String, "Psalm")
        app.buttons["Czytaj"].tap()
        _ = try result()
        checkPlayback()
    }

    func testCzytanieWTleIPowrotDoKarty() throws {
        app.buttons["Czytaj"].tap()
        _ = try result()
        app.buttons["Czytaj na głos"].tap()
        let pause = app.buttons["Wstrzymaj czytanie"]
        XCTAssertTrue(pause.waitForExistence(timeout: 8))
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 8))
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 8))
        app.activate()
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()
        XCTAssertTrue(app.buttons["Wznów czytanie"].exists)
        selectTab("Ustawienia")
        XCTAssertTrue(app.buttons["Odsłuchaj próbkę"].exists)
        selectTab("Liturgia")
        XCTAssertTrue(app.buttons["Czytaj na głos"].exists)
    }

    func testPauzaZCentrumSterowania() throws {
        app.buttons["Czytaj"].tap()
        _ = try result()
        app.buttons["Czytaj na głos"].tap()
        XCTAssertTrue(app.buttons["Wstrzymaj czytanie"].waitForExistence(timeout: 8))
        defer { app.terminate() }
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.002))
        start.press(forDuration: 0.12, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.72)))
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let center = XCUIApplication(bundleIdentifier: "com.apple.ControlCenter")
        let names = NSPredicate(format: "label IN %@ OR identifier ==[c] %@ OR identifier CONTAINS[c] %@",
                                ["Pauza", "Wstrzymaj", "Wstrzymaj odtwarzanie", "Pause"], "Pause", "playpause")
        let systemPause = system.descendants(matching: .any).matching(names).firstMatch
        let centerPause = center.descendants(matching: .any).matching(names).firstMatch
        if systemPause.waitForExistence(timeout: 5) { systemPause.tap() }
        else if centerPause.waitForExistence(timeout: 5) { centerPause.tap() }
        else { throw XCTSkip("W bieżącym układzie Centrum sterowania XCTest nie znalazł kontrolki odtwarzania.") }
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["Wznów czytanie"].waitForExistence(timeout: 5))
        app.buttons["Zatrzymaj czytanie"].tap()
    }

    func testUstawieniaSyntezyITrwalosc() throws {
        selectTab("Ustawienia")
        let rate = app.sliders["Szybkość mowy"], volume = app.sliders["Głośność"]
        app.buttons["Przywróć domyślną syntezę"].tap()
        defer { app.buttons["Przywróć domyślną syntezę"].tap() }
        XCTAssertEqual(rate.value as? String, "6 z 11, domyślna")
        rate.adjust(toNormalizedSliderPosition: 0.7)
        volume.adjust(toNormalizedSliderPosition: 0.6)
        let chosenRate = try XCTUnwrap(rate.value as? String)
        let chosenVolume = try XCTUnwrap(volume.value as? String)
        XCTAssertNotEqual(chosenRate, "6 z 11, domyślna")
        XCTAssertNotEqual(chosenVolume, "100 procent")
        let voice = app.sliders["Głos"]
        voice.adjust(toNormalizedSliderPosition: 0.02)
        let chosen = try XCTUnwrap(voice.value as? String)
        app.terminate()
        app.launch()
        selectTab("Ustawienia")
        XCTAssertEqual(rate.value as? String, chosenRate)
        XCTAssertEqual(volume.value as? String, chosenVolume)
        XCTAssertEqual(voice.value as? String, chosen)
        app.buttons["Przywróć domyślną syntezę"].tap()
        app.buttons["Odsłuchaj próbkę"].tap()
        XCTAssertTrue(app.buttons["Zatrzymaj próbkę"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Odsłuchaj próbkę"].waitForExistence(timeout: 35))
    }

    func testCzytanieIZapisLiturgii() throws {
        app.buttons["Czytaj"].tap()
        let field = try result()
        XCTAssertTrue((field.value as? String ?? "").contains("Źródło: TwojaBiblia.pl"))
        checkPlayback()
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
        checkPlayback()
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
