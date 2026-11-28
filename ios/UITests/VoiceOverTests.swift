import XCTest

#if compiler(>=6.4)
@available(iOS 27.0, *)
@MainActor
final class VoiceOverTests: XCTestCase {
    func testSyntezaINazwiskaZVoiceOver() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        let voice = XCUIDevice.shared.voiceOverService
        let wasEnabled = voice.isEnabled
        if !wasEnabled { try voice.enable() }
        defer { if !wasEnabled { try? voice.disable() } }
        let center = CGVector(dx: 0.5, dy: 0.5)
        func focus(_ element: XCUIElement, _ label: String) throws {
            let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                .descendants(matching: .any)["NotificationShortLookView"]
            for _ in 0..<2 {
                if banner.exists {
                    let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: banner)
                    XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 18), .completed)
                }
                element.coordinate(withNormalizedOffset: center).tap()
                let said = try voice.currentSpeech().utterance
                if said.contains(label) {
                    print("VoiceOver potwierdził: " + label)
                    return
                }
            }
            XCTFail("VoiceOver nie potwierdził elementu: " + label)
        }
        func activate() { app.coordinate(withNormalizedOffset: center).doubleTap() }
        try focus(app.tabBars.buttons["Ustawienia"], "Ustawienia")
        activate()
        let engine = app.sliders["Silnik mowy"]
        try focus(engine, "Silnik mowy")
        let engineName = try XCTUnwrap(engine.value as? String)
        if engine.isEnabled {
            app.swipeUp()
            if engine.value as? String != engineName {
                let selected = try XCTUnwrap(engine.value as? String)
                XCTAssertTrue(try voice.currentSpeech().utterance.localizedCaseInsensitiveContains(selected))
                app.swipeDown()
                XCTAssertEqual(engine.value as? String, engineName)
            }
        }
        let speed = app.sliders["Szybkość mowy"]
        try focus(speed, "regulacja")
        let initial = try XCTUnwrap(Int((speed.value as? String ?? "").prefix(while: \.isNumber)))
        if initial == 100 { app.swipeDown() } else { app.swipeUp() }
        let changed = initial == 100 ? initial - 5 : initial + 5
        XCTAssertEqual(speed.value as? String, "\(changed) procent")
        let spoken = try voice.currentSpeech().utterance
        XCTAssertTrue(spoken.contains("\(changed)"), spoken)
        if initial == 100 { app.swipeUp() } else { app.swipeDown() }
        let slider = app.sliders["Głos"]
        try focus(slider, "regulacja")
        let original = try XCTUnwrap(slider.value as? String)
        app.swipeUp()
        let selected = try XCTUnwrap(slider.value as? String)
        XCTAssertNotEqual(selected, original)
        let announcement = try voice.currentSpeech().utterance
        XCTAssertTrue(announcement.localizedCaseInsensitiveContains(selected), announcement)
        app.swipeDown()
        XCTAssertEqual(slider.value as? String, original)
        try focus(app.buttons["Odsłuchaj próbkę"], "Odsłuchaj próbkę")
        activate()
        XCTAssertTrue(app.buttons["Zatrzymaj próbkę"].waitForExistence(timeout: 3))
        try focus(app.sliders["Głośność"], "regulacja")
        var said = ""
        for _ in 0..<10 {
            said = try voice.moveForward().utterance
            if said.contains("Autorzy i źródła") { break }
        }
        XCTAssertTrue(said.contains("Autorzy i źródła"), said)
        activate()
        try focus(app.staticTexts["Pomysłodawca i autor wersji Windows: Grzegorz Przystupa"], "Grzegorz Przystupa")
        XCTAssertTrue(try voice.moveForward().utterance.contains("Mieczysław Bąk"))
        XCTAssertTrue(try voice.moveForward().utterance.localizedCaseInsensitiveContains("GitHub"))
    }

    func testUstawieniaCzytaniaZMowa() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        let voice = XCUIDevice.shared.voiceOverService
        let enabled = voice.isEnabled
        if !enabled { try voice.enable() }
        defer { if !enabled { try? voice.disable() } }
        let center = CGVector(dx: 0.5, dy: 0.5)
        app.buttons["Ustawienia czytania"].coordinate(withNormalizedOffset: center).tap()
        XCTAssertTrue(try voice.currentSpeech().utterance.contains("Ustawienia czytania"))
        app.coordinate(withNormalizedOffset: center).doubleTap()
        let slider = app.sliders["Wielkość tekstu Biblii"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        slider.coordinate(withNormalizedOffset: center).tap()
        let speech = try voice.currentSpeech().utterance
        XCTAssertTrue(speech.contains("Wielkość tekstu Biblii") && speech.contains("regulacja"), speech)
        let original = try XCTUnwrap(slider.value as? String)
        let maximum = original == "Bardzo duży"
        if maximum { app.swipeDown() } else { app.swipeUp() }
        let changed = try voice.currentSpeech().utterance
        if maximum { app.swipeUp() } else { app.swipeDown() }
        XCTAssertEqual(slider.value as? String, original)
        print("VoiceOver, ustawienia: \(speech) → \(changed) → \(try voice.currentSpeech().utterance)")
        XCTAssertFalse(changed.isEmpty)
    }

    func testGestyDatyICzytanieZPowrotem() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        let voice = XCUIDevice.shared.voiceOverService
        let initiallyEnabled = voice.isEnabled
        if !initiallyEnabled { try voice.enable() }
        defer { if !initiallyEnabled { try? voice.disable() } }
        let center = CGVector(dx: 0.5, dy: 0.5)
        for (index, name) in ["Wybierz miesiąc", "Wybierz dzień", "Wybierz rok"].enumerated() {
            let wheel = app.pickerWheels.element(boundBy: index)
            wheel.coordinate(withNormalizedOffset: center).tap()
            let speech = try voice.currentSpeech().utterance
            XCTAssertTrue(speech.contains(name) && speech.contains("regulacja"), speech)
            let initial = try XCTUnwrap(wheel.value as? String)
            // Z ostatniej pozycji zaczynamy w dół, żeby nie gestykulować poza zakresem.
            let atEnd = speech.range(of: #"(\d+) z\s+\1$"#, options: .regularExpression) != nil
            if atEnd { app.swipeDown() } else { app.swipeUp() }
            XCTAssertNotEqual(wheel.value as? String, initial)
            print("Regulacja \(name): \(try voice.currentSpeech().utterance)")
            if atEnd { app.swipeUp() } else { app.swipeDown() }
            XCTAssertEqual(wheel.value as? String, initial)
        }
        app.buttons["Czytaj"].coordinate(withNormalizedOffset: center).tap()
        app.coordinate(withNormalizedOffset: center).doubleTap()
        XCTAssertTrue(app.textViews["tekstWyniku"].waitForExistence(timeout: 30))
        let result = try voice.currentSpeech().utterance
        print("Fokus po pobraniu: \(result.prefix(120))")
        XCTAssertTrue(result.contains("Czytaj na głos"), String(result.prefix(120)))
        let text = try voice.moveForward().utterance
        XCTAssertTrue(text.localizedCaseInsensitiveContains("czytanie") || text.contains("20"), String(text.prefix(120)))
        app.buttons["Czytaj na głos"].coordinate(withNormalizedOffset: center).tap()
        app.coordinate(withNormalizedOffset: center).doubleTap()
        let pause = app.buttons["Wstrzymaj czytanie"]
        XCTAssertTrue(pause.waitForExistence(timeout: 8))
        pause.coordinate(withNormalizedOffset: center).tap()
        XCTAssertTrue(try voice.currentSpeech().utterance.contains("Wstrzymaj czytanie"))
        XCTAssertTrue(try voice.moveForward().utterance.contains("Czytaj od początku"))
        XCTAssertTrue(pause.exists)
        let back = app.navigationBars.buttons.firstMatch
        back.coordinate(withNormalizedOffset: center).tap()
        app.coordinate(withNormalizedOffset: center).doubleTap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
    }

    func testMowaNaPieciuKartach() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        let voice = XCUIDevice.shared.voiceOverService
        let initiallyEnabled = voice.isEnabled
        if !initiallyEnabled { try voice.enable() }
        defer { if !initiallyEnabled { try? voice.disable() } }
        var transcript: [String] = []
        defer {
            let attachment = XCTAttachment(string: transcript.joined(separator: "\n"))
            attachment.name = "Komunikaty rzeczywistej usługi VoiceOver"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func record(_ output: String, contains expected: String) {
            transcript.append(output)
            print("VoiceOver: \(output)")
            XCTAssertTrue(output.localizedCaseInsensitiveContains(expected), "Oczekiwano: \(expected); odczytano: \(output)")
        }
        func focus(_ element: XCUIElement, _ name: String) throws {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            record(try voice.currentSpeech().utterance, contains: name)
        }

        try focus(app.pickerWheels.element(boundBy: 0), "Wybierz miesiąc")
        record(try voice.moveForward().utterance, contains: "Wybierz dzień")
        record(try voice.moveForward().utterance, contains: "Wybierz rok")
        let part = app.sliders["Część liturgii"]
        try focus(part, "Cała liturgia")
        app.swipeUp()
        record(try voice.currentSpeech().utterance, contains: "Pierwsze czytanie")
        app.swipeDown()
        record(try voice.currentSpeech().utterance, contains: "Cała liturgia")
        let tabTitles = ["Liturgia", "Czytaj Biblię", "Losuj cytat", "Wyszukaj", "Ustawienia"]
        for (index, title) in tabTitles.enumerated() {
            let tab = app.tabBars.buttons[title]
            try focus(tab, title)
            let output = (transcript.last ?? "").components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.joined(separator: " ")
            XCTAssertTrue(output.contains("\(index + 1) z 5") || output.contains("\(index + 1) of 5"), output)
            if index > 0 {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
                XCTAssertTrue(tab.isSelected, title)
                let first: XCUIElement
                let value: String
                switch index {
                case 1: first = app.sliders["Co chcesz czytać"]; value = "Cała Biblia"
                case 2: first = app.sliders["Kategoria cytatu"]; value = "Losowo"
                case 3: first = app.textFields["Słowa kluczowe"]; value = "Słowa kluczowe"
                default: first = app.sliders["Głos"]; value = "Głos"
                }
                try focus(first, value)
            }
        }
    }
}
#endif
