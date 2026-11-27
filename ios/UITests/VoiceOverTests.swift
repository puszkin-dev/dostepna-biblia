import XCTest

#if compiler(>=6.4)
@available(iOS 27.0, *)
@MainActor
final class VoiceOverTests: XCTestCase {
    func testMowaNaCzterechKartach() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()
        let voice = XCUIDevice.shared.voiceOverService
        let initiallyEnabled = voice.isEnabled
        if !initiallyEnabled { try voice.enable() }
        defer { if !initiallyEnabled { try? voice.disable() } }

        func scan(until target: String, limit: Int = 30) throws -> [String] {
            var spoken = [try voice.currentSpeech().utterance]
            for _ in 0..<limit {
                if spoken.last?.localizedCaseInsensitiveContains(target) == true { break }
                spoken.append(try voice.moveForward().utterance)
            }
            let log = spoken.joined(separator: "\n")
            let attachment = XCTAttachment(string: log)
            attachment.name = "Mowa VoiceOver: " + target
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTAssertTrue(spoken.last?.localizedCaseInsensitiveContains(target) == true, log)
            return spoken
        }

        let month = try scan(until: "Wybierz miesiąc").last ?? ""
        XCTAssertTrue(month.localizedCaseInsensitiveContains("regul") || month.localizedCaseInsensitiveContains("adjustable"), month)
        let day = try voice.moveForward().utterance
        let year = try voice.moveForward().utterance
        XCTAssertTrue(day.contains("Wybierz dzień"), day)
        XCTAssertTrue(year.contains("Wybierz rok"), year)
        let tabs = try scan(until: "Wyszukaj")
        for title in ["Liturgia", "Czytaj Biblię", "Losuj cytat", "Wyszukaj"] {
            XCTAssertTrue(tabs.contains { $0.contains(title) }, tabs.joined(separator: "\n"))
        }
        for (tab, label) in [("Czytaj Biblię", "Wybierz księgę"), ("Losuj cytat", "Kategoria cytatu"), ("Wyszukaj", "Słowa kluczowe")] {
            app.tabBars.buttons[tab].tap()
            _ = try scan(until: label)
        }
    }
}
#endif
