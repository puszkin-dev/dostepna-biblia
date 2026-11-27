import XCTest

@MainActor
final class VisualTests: XCTestCase {
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

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<6 {
            if scroll.frame.insetBy(dx: 0, dy: 12).contains(element.frame.centerPoint) { return }
            let previous = element.frame
            if previous.midY < scroll.frame.midY { scroll.swipeDown() } else { scroll.swipeUp() }
            if previous == element.frame { break }
        }
    }

    private func openSettings() {
        let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            .descendants(matching: .any)["NotificationShortLookView"]
        if banner.exists {
            let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: banner)
            XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 15), .completed)
        }
        app.buttons["Ustawienia czytania"].tap()
        XCTAssertTrue(app.sliders["Wielkość tekstu Biblii"].waitForExistence(timeout: 5))
    }

    private func landscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let window = app.windows.firstMatch
        let rotated = expectation(for: NSPredicate { _, _ in window.frame.width > window.frame.height }, evaluatedWith: window)
        wait(for: [rotated], timeout: 8)
    }

    func testEkranyFormularzy() throws {
        capture("01-liturgia")
        openSettings()
        let size = app.sliders["Wielkość tekstu Biblii"]
        XCTAssertTrue(size.exists)
        capture("02-ustawienia")
        app.navigationBars.buttons.firstMatch.tap()
        for (index, tab) in ["Czytaj Biblię", "Losuj cytat", "Wyszukaj"].enumerated() {
            app.tabBars.buttons[tab].tap()
            capture("0\(index + 3)-\(tab)")
        }
        app.scrollViews.buttons["Szukaj"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 6))
        capture("06-pusta-fraza")
        app.alerts.buttons["OK"].tap()
    }

    func testWersetyIZapamietanaCzcionka() throws {
        openSettings()
        let size = app.sliders["Wielkość tekstu Biblii"]
        let original = size.value as? String
        defer {
            app.terminate()
            app.launch()
            openSettings()
            if let original, let i = ["Mniejszy", "Standardowy", "Większy", "Duży", "Bardzo duży"].firstIndex(of: original) {
                size.adjust(toNormalizedSliderPosition: CGFloat(i) / 4)
            }
        }
        size.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(size.value as? String, "Bardzo duży")
        app.terminate()
        app.launch()
        openSettings()
        XCTAssertEqual(size.value as? String, "Bardzo duży")
        capture("07-ustawienia-powiekszone")
        app.buttons["Przywróć domyślny rozmiar"].tap()
        XCTAssertEqual(size.value as? String, "Standardowy")
        size.adjust(toNormalizedSliderPosition: 1)
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Czytaj Biblię"].tap()
        let chapters = app.sliders["Wybierz rozdział"]
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: chapters)
        waitForExpectations(timeout: 30)
        reveal(chapters)
        chapters.adjust(toNormalizedSliderPosition: 1)
        XCTAssertEqual(chapters.value as? String, "50")
        reveal(app.buttons["Czytaj"])
        app.buttons["Czytaj"].tap()
        let reader = app.textViews["tekstWyniku"]
        XCTAssertTrue(reader.waitForExistence(timeout: 35), app.debugDescription)
        capture("08-rozdzial")
        app.buttons["Przejdź do wersetu"].tap()
        XCTAssertTrue(app.tables.cells.firstMatch.waitForExistence(timeout: 8))
        capture("09-wersety")
        app.tables.cells.element(boundBy: 1).tap()
        XCTAssertTrue(reader.exists)
        landscape()
        defer { XCUIDevice.shared.orientation = .portrait }
        capture("10-poziomo")
    }

    func testDuzeLiteryIMalyEkran() throws {
        capture("11-glowny-rozmiar-systemowy")
        if app.sliders["Wybierz miesiąc"].exists {
            XCTAssertEqual(app.pickerWheels.count, 0)
            XCTAssertTrue(app.sliders["Wybierz dzień"].exists)
            XCTAssertTrue(app.sliders["Wybierz rok"].exists)
        }
        openSettings()
        capture("12-ustawienia-rozmiar-systemowy")
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped])
        landscape()
        defer { XCUIDevice.shared.orientation = .portrait }
        capture("13-ustawienia-poziomo")
    }

    func testNoweUstawieniaIAutorzy() throws {
        app.tabBars.buttons["Ustawienia"].tap()
        capture("14-synteza")
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped])
        let about = app.buttons["Autorzy i źródła"]
        reveal(about)
        about.tap()
        let designer = app.staticTexts["Projektant wersji iOS: Mieczysław Bąk"]
        XCTAssertTrue(designer.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Pomysłodawca i autor wersji Windows: Grzegorz Przystupa"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Wersja 1.0, kompilacja ")).firstMatch.exists)
        reveal(designer)
        capture("15-autorzy")
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped])
        let link = app.descendants(matching: .any).matching(identifier: "Kod źródłowy oryginalnej wersji Windows na GitHubie").firstMatch
        reveal(link)
        link.tap()
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10) || app.state == .runningBackgroundSuspended)
        app.activate()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.tabBars.buttons["Ustawienia"].isSelected)
    }

    func testWygladCzytnikaPodczasMowy() throws {
        let read = app.buttons["Czytaj"]
        reveal(read)
        read.tap()
        let text = app.textViews["tekstWyniku"]
        XCTAssertTrue(text.waitForExistence(timeout: 35))
        app.buttons["Czytaj na głos"].tap()
        let pause = app.buttons["Wstrzymaj czytanie"]
        XCTAssertTrue(pause.waitForExistence(timeout: 8))
        capture("16-mowa-w-czytniku")
        XCTAssertGreaterThanOrEqual(text.frame.height, 44)
        XCTAssertLessThanOrEqual(pause.frame.maxY, text.frame.minY)
        XCTAssertTrue(app.buttons["Zatrzymaj czytanie"].isHittable)
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped])
        app.buttons["Zatrzymaj czytanie"].tap()
    }
}

private extension CGRect {
    var centerPoint: CGPoint { CGPoint(x: midX, y: midY) }
}
