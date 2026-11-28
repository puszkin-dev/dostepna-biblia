import XCTest

#if compiler(>=6.4)
@available(iOS 27.0, *)
@MainActor
final class VoiceOverTests: XCTestCase {
    private func focusEngine(_ engine: XCUIElement, reader: XCUIVoiceOverService) throws {
        let banner = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            .descendants(matching: .any)["NotificationShortLookView"]
        var spoken = ""
        for _ in 0..<2 {
            if banner.exists {
                let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: banner)
                XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 18), .completed)
            }
            engine.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            spoken = try reader.currentSpeech().utterance
            if spoken.contains("Silnik mowy") { return }
            // Po włączeniu usługi system czasem pozostawia fokus na nagłówku karty.
            for _ in 0..<3 where spoken.localizedCaseInsensitiveContains("nagłówek") {
                spoken = try reader.moveForward().utterance
                if spoken.contains("Silnik mowy") { return }
            }
        }
        XCTFail("Nie udało się rozpocząć na silniku mowy: " + spoken)
    }

    func testPierwszyGestPoZmianieKazdegoSilnika() async throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        let vo = XCUIDevice.shared.voiceOverService
        let wasEnabled = vo.isEnabled
        if wasEnabled { try vo.disable() }
        defer {
            if wasEnabled && !vo.isEnabled { try? vo.enable() }
            if !wasEnabled && vo.isEnabled { try? vo.disable() }
        }
        app.launch()
        app.tabBars.buttons["Ustawienia"].tap()
        let engine = app.sliders["Silnik mowy"]
        XCUIDevice.shared.orientation = .portrait
        let originalEngine = engine.normalizedSliderPosition
        let originalVoice = app.sliders["Głos"]
        let originalPosition = originalVoice.exists ? originalVoice.normalizedSliderPosition : nil
        defer {
            if vo.isEnabled { try? vo.disable() }
            engine.adjust(toNormalizedSliderPosition: originalEngine)
            if let originalPosition, originalVoice.exists {
                originalVoice.adjust(toNormalizedSliderPosition: originalPosition)
            }
        }
        engine.adjust(toNormalizedSliderPosition: 0)
        let frame = app.frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let first = try XCTUnwrap(engine.value as? String)
        let cloud = "Eleven Labs — naturalne głosy neuronowe"
        try vo.enable()
        // Ustawiamy wyłącznie początkowy fokus. Właściwe próby nie ponawiają żadnego gestu.
        try focusEngine(engine, reader: vo)

        func switchAndRead(forward: Bool) async throws -> String {
            let done = expectation(description: "Dwa szybkie gesty na iPhonie")
            BibliaFlicki(center, forward) { success in
                XCTAssertTrue(success, "XCTest nie wykonał sekwencji dotknięć.")
                done.fulfill()
            }
            await fulfillment(of: [done], timeout: 15)
            let spoken = try vo.currentSpeech().utterance
            let name = try XCTUnwrap(engine.value as? String)
            let slider = app.sliders["Głos"]
            let single = app.staticTexts["Głos"]
            if slider.exists || single.exists {
                let item = slider.exists ? slider : single
                let value = try XCTUnwrap(item.value as? String)
                XCTAssertTrue(spoken.localizedCaseInsensitiveContains("Głos"), spoken)
                XCTAssertTrue(spoken.localizedCaseInsensitiveContains(value.components(separatedBy: ",").first ?? value), spoken)
                if value.contains("jedyny głos") {
                    XCTAssertTrue(spoken.contains("jedyny głos"), spoken)
                    XCTAssertFalse(spoken.localizedCaseInsensitiveContains("regulacja"), spoken)
                }
            } else {
                XCTAssertEqual(name, cloud)
                XCTAssertTrue(spoken.contains("klucz") && spoken.contains("Eleven Labs") && spoken.localizedCaseInsensitiveContains("przycisk"), spoken)
            }
            XCTAssertFalse(spoken.localizedCaseInsensitiveContains("wygaszony"), spoken)
            XCTAssertFalse(spoken.localizedCaseInsensitiveContains("wyszarzony"), spoken)
            if forward && (name == "SynTalk" || name == cloud) {
                let picture = XCTAttachment(screenshot: app.screenshot())
                picture.name = name == cloud ? "Panel-chmura" : "Panel-jeden-glos"
                picture.lifetime = .keepAlways
                add(picture)
            }
            print("Pierwszy flick: \(name) → \(spoken)")
            let back = try vo.moveBackward().utterance
            XCTAssertTrue(back.contains("Silnik mowy") && back.localizedCaseInsensitiveContains(name), back)
            return name
        }
        var visited = [first]
        while visited.last != cloud {
            let name = try await switchAndRead(forward: true)
            XCTAssertFalse(visited.contains(name), "Suwak utknął na: \(name)")
            visited.append(name)
        }
        for expected in visited.dropLast().reversed() {
            let name = try await switchAndRead(forward: false)
            XCTAssertEqual(name, expected)
        }
    }

    func testPoleKluczaZVoiceOver() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL", "-silnikEleven", "YES"]
        let vo = XCUIDevice.shared.voiceOverService
        let initial = vo.isEnabled
        if initial { try vo.disable() }
        defer {
            if initial && !vo.isEnabled { try? vo.enable() }
            if !initial && vo.isEnabled { try? vo.disable() }
        }
        app.launch()
        app.tabBars.buttons["Ustawienia"].tap()
        try vo.enable()
        try focusEngine(app.sliders["Silnik mowy"], reader: vo)
        let next = try vo.moveForward().utterance
        let field = app.secureTextFields["Klucz API Eleven Labs"]
        let shortcut = next.localizedCaseInsensitiveContains("klucz") && next.contains("Eleven Labs")
        XCTAssertTrue(shortcut || next.localizedCaseInsensitiveContains("Głos"), next)
        #if targetEnvironment(simulator)
        // Na symulatorze badamy kolejność mowy, a edycję osobno dotykiem.
        // Aktywację dwukrotnym stuknięciem z VoiceOver sprawdza rzeczywisty telefon.
        XCTAssertTrue(try vo.moveForward().utterance.contains("Szybkość mowy"))
        XCTAssertTrue(try vo.moveForward().utterance.contains("Głośność"))
        let key = try vo.moveForward().utterance
        XCTAssertTrue(key.contains("Klucz API Eleven Labs"), key)
        try vo.disable()
        field.tap()
        app.typeText("x")
        XCTAssertFalse((field.value as? String ?? "").isEmpty)
        print("Symulator: \(next) → szybkość, głośność → \(key). Potwierdzono wpisywanie dotykiem.")
        #else
        if !shortcut {
            XCTAssertTrue(try vo.moveForward().utterance.contains("Szybkość mowy"))
            XCTAssertTrue(try vo.moveForward().utterance.contains("Głośność"))
            let key = try vo.moveForward().utterance
            XCTAssertTrue(key.contains("Klucz API Eleven Labs"), key)
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        XCTAssertTrue(field.exists)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        let spoken = try vo.currentSpeech().utterance
        XCTAssertTrue(spoken.contains("Klucz API Eleven Labs"), spoken)
        print("Panel i pole klucza: \(next) → \(spoken)")
        #endif
    }

    func testOdbiorSkonfigurowanejInstalacjiNaZyczenie() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["BIBLIA_ODBIOR_TELEFONU"] == "1",
                          "Wyłącznie na polecenie pozostawienia skonfigurowanego telefonu.")
        continueAfterFailure = false
        let vo = XCUIDevice.shared.voiceOverService
        if vo.isEnabled { try vo.disable() }
        defer { if !vo.isEnabled { try? vo.enable() } }
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        app.tabBars.buttons["Ustawienia"].tap()
        let engine = app.sliders["Silnik mowy"]
        engine.adjust(toNormalizedSliderPosition: 1)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Ustawienia"].tap()
        let name = "Eleven Labs — naturalne głosy neuronowe"
        XCTAssertEqual(engine.value as? String, name)
        XCTAssertTrue(app.buttons["Usuń zapisany klucz"].exists)
        let selected = try XCTUnwrap(app.sliders["Głos"].value as? String)
        try vo.enable()
        try focusEngine(engine, reader: vo)
        let service = try vo.currentSpeech().utterance
        XCTAssertTrue(service.contains(name), service)
        let spoken = try vo.moveForward().utterance
        XCTAssertTrue(spoken.contains(selected), spoken)
        print("Po restarcie: \(service) → \(spoken).")
    }

    func testElevenPoRestarcieZVoiceOver() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        let vo = XCUIDevice.shared.voiceOverService
        let previous = vo.isEnabled
        if previous { try vo.disable() }
        defer {
            if previous && !vo.isEnabled { try? vo.enable() }
            if !previous && vo.isEnabled { try? vo.disable() }
        }
        app.launch()
        app.tabBars.buttons["Ustawienia"].tap()
        let resume = app.buttons["wznowOstatniaSesje"]
        try XCTSkipUnless(resume.exists && (resume.value as? String) == "Próba krótkiego czytania ElevenLabs", "Brak przygotowanej sesji odbiorowej.")
        let engine = app.sliders["Silnik mowy"]
        XCTAssertEqual(engine.value as? String, "Eleven Labs — naturalne głosy neuronowe")
        let secret = app.secureTextFields["Klucz API Eleven Labs"]
        XCTAssertTrue(secret.exists)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "ElevenLabs-ustawienia"
        image.lifetime = .keepAlways
        add(image)
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped])
        try vo.enable()
        let center = CGVector(dx: 0.5, dy: 0.5)
        func focus(_ item: XCUIElement, _ name: String) throws {
            item.coordinate(withNormalizedOffset: center).tap()
            let spoken = try vo.currentSpeech().utterance
            XCTAssertTrue(spoken.localizedCaseInsensitiveContains(name), spoken)
            print("Fokus VoiceOver: \(spoken)")
        }
        try focus(secret, "Klucz API")
        let slider = app.sliders["Głos"]
        let original = try XCTUnwrap(slider.value as? String)
        try focus(slider, "regulacja")
        app.swipeUp()
        let changed = try XCTUnwrap(slider.value as? String)
        XCTAssertNotEqual(original, changed)
        XCTAssertTrue(try vo.currentSpeech().utterance.contains(changed))
        app.swipeDown()
        XCTAssertEqual(slider.value as? String, original)
        try vo.disable()
        // Przycisk jest pod regulacjami; XCTest przewija do niego przed aktywacją.
        resume.tap()
        let text = app.textViews["tekstWyniku"]
        XCTAssertTrue(text.waitForExistence(timeout: 6))
        XCTAssertTrue((text.value as? String)?.contains("Amen.") == true)
        XCTAssertTrue(app.buttons["Czytaj na głos"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.alerts.firstMatch.exists)
        app.tabBars.buttons["Ustawienia"].tap()
        XCTAssertFalse(resume.exists)
    }

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
