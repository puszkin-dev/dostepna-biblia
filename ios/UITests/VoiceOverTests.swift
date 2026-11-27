import XCTest

#if compiler(>=6.4)
@available(iOS 27.0, *)
@MainActor
final class VoiceOverTests: XCTestCase {
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
        XCTAssertTrue(result.localizedCaseInsensitiveContains("czytanie") || result.contains("20"), String(result.prefix(120)))
        let back = app.navigationBars.buttons.firstMatch
        back.coordinate(withNormalizedOffset: center).tap()
        app.coordinate(withNormalizedOffset: center).doubleTap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
    }

    func testMowaNaCzterechKartach() throws {
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
        let tabTitles = ["Liturgia", "Czytaj Biblię", "Losuj cytat", "Wyszukaj"]
        for (index, title) in tabTitles.enumerated() {
            let tab = app.tabBars.buttons[title]
            try focus(tab, title)
            let output = (transcript.last ?? "").components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.joined(separator: " ")
            XCTAssertTrue(output.contains("\(index + 1) z 4") || output.contains("\(index + 1) of 4"), output)
            if index > 0 {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
                XCTAssertTrue(tab.isSelected, title)
                let first: XCUIElement
                let value: String
                switch index {
                case 1: first = app.sliders["Co chcesz czytać"]; value = "Cała Biblia"
                case 2: first = app.sliders["Kategoria cytatu"]; value = "Losowo"
                default: first = app.textFields["Słowa kluczowe"]; value = "Słowa kluczowe"
                }
                try focus(first, value)
            }
        }
    }
}
#endif
