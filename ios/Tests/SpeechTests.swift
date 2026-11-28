import AVFoundation
import XCTest
@testable import DostepnaBiblia

@MainActor
final class SpeechTests: XCTestCase {
    func testUstawieniaGraniceUszkodzenieIReset() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let p = SpeechPreferences(defaults)
        XCTAssertEqual(p.speed, 50)
        XCTAssertEqual(p.volume, 100)
        defaults.set(7, forKey: "tempoMowy")
        defaults.set(3, forKey: "glosnoscMowy")
        XCTAssertEqual(p.speed, 70)
        XCTAssertEqual(p.volume, 30)
        p.speed = Int.min
        p.volume = Int.max
        XCTAssertEqual(p.speed, 0)
        XCTAssertEqual(p.volume, 100)
        defaults.set("uszkodzone", forKey: "tempoProcent")
        defaults.set(99, forKey: "glosnoscProcent")
        XCTAssertEqual(p.speed, 50)
        XCTAssertEqual(p.volume, 100)
        p.voiceID = "brak-takiego-głosu"
        let reader = SpeechReader.shared
        defer { reader.stop() }
        XCTAssertNotNil(try reader.start("Sprawdzenie zastępczego głosu.", settings: p))
        XCTAssertNil(p.voiceID)
        reader.stop()
        p.reset()
        XCTAssertEqual(p.speed, 50)
        XCTAssertEqual(p.volume, 100)
    }

    func testKazdyProcentOdZapisuDoWypowiedzi() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SpeechPreferences(defaults)
        let voice = try XCTUnwrap(AVSpeechSynthesisVoice(language: "pl-PL"))
        XCTAssertEqual(SpeechPreferences.percentages, Array(stride(from: 0, through: 100, by: 5)))
        for percent in SpeechPreferences.percentages {
            settings.speed = percent
            settings.volume = 100 - percent
            let loaded = SpeechPreferences(defaults)
            let item = loaded.utterance("Sprawdzenie skali.", voice: voice)
            XCTAssertEqual(loaded.speed, percent)
            XCTAssertEqual(loaded.volume, 100 - percent)
            XCTAssertEqual(item.rate, Float(percent) / 100, accuracy: 0.00001)
            XCTAssertEqual(item.volume, Float(100 - percent) / 100, accuracy: 0.00001)
            XCTAssertEqual(item.voice?.identifier, voice.identifier)
            XCTAssertFalse(item.prefersAssistiveTechnologySettings)
        }
    }

    func testKatalogSilnikowIPolskichWariantow() throws {
        let all = AVSpeechSynthesisVoice.speechVoices()
        XCTAssertTrue(VoiceGroup.isPolish("PL_pl"))
        XCTAssertTrue(VoiceGroup.isPolish("pl-PO"))
        XCTAssertFalse(VoiceGroup.isPolish("plx"))
        XCTAssertFalse(VoiceGroup.isPolish(""))
        let expected = Set(all.filter { VoiceGroup.isPolish($0.language) }.map(\.identifier))
        let groups = VoiceGroup.catalog(all + all.reversed())
        let ids = groups.flatMap(\.voices).map(\.identifier)
        XCTAssertFalse(expected.isEmpty)
        XCTAssertEqual(Set(ids), expected)
        XCTAssertEqual(ids.count, expected.count)
        XCTAssertEqual(ids, VoiceGroup.catalog(all.reversed()).flatMap(\.voices).map(\.identifier))
        XCTAssertTrue(VoiceGroup.catalog(all.filter { $0.language.hasPrefix("en") }).isEmpty)
        XCTAssertNil(VoiceGroup.automatic(in: []))
        XCTAssertTrue(expected.contains(try XCTUnwrap(VoiceGroup.automatic(in: groups)).identifier))
        for group in groups {
            print("Silnik \(group.name): \(group.voices.count) polskich głosów")
            XCTAssertEqual(Set(group.labels).count, group.voices.count)
        }
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); SpeechReader.shared.stop() }
        let settings = SpeechPreferences(defaults)
        settings.voiceID = try XCTUnwrap(all.first { $0.language.hasPrefix("en") }).identifier
        XCTAssertNotNil(try SpeechReader.shared.start("Po polsku.", settings: settings))
        XCTAssertNil(settings.voiceID)
    }
    func testNatychmiastowaZmianaPaneluSilnika() throws {
        let prefs = SpeechPreferences()
        let keys = ["silnikEleven", "glosMowy", "katalogEleven", "glosEleven"]
        let saved = keys.map { prefs.defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, saved) { prefs.defaults.set(value, forKey: key) }
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let screen = SettingsScreen()
        prefs.cloudSelected = false
        prefs.voiceID = nil
        window.rootViewController = UINavigationController(rootViewController: screen)
        window.isHidden = false
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        let controls = screen.choices.arrangedSubviews.compactMap { $0 as? ChoiceSlider }
        let engine = try XCTUnwrap(controls.first { $0.accessibilityLabel == "Silnik mowy" })
        let voice = try XCTUnwrap(controls.compactMap { $0 as? VoiceChoiceSlider }.first)
        let last = Int(engine.maximumValue)
        var timings: [Double] = []
        let examples = [ElevenVoice(voice_id: "a", name: "Ala"), ElevenVoice(voice_id: "b", name: "Jan")]
        for count in 0...examples.count {
            prefs.cloudVoices = Array(examples.prefix(count))
            prefs.cloudVoice = prefs.cloudVoices.first?.voice_id
            screen.refresh()
            for index in Array(0...last) + Array((0..<last).reversed()) {
                guard Int(engine.value.rounded()) != index else { continue }
                let before = CACurrentMediaTime()
                engine.value = Float(index)
                engine.sendActions(for: .valueChanged)
                screen.view.layoutIfNeeded()
                CATransaction.flush()
                timings.append((CACurrentMediaTime() - before) * 1000)
                XCTAssertEqual(prefs.cloudSelected, index == last)
                if index == last {
                    XCTAssertFalse(voice.isHidden)
                    if count == 0 {
                        XCTAssertEqual(voice.accessibilityTraits, .button)
                        XCTAssertTrue(voice.accessibilityLabel?.contains("klucz") == true)
                    } else if count == 1 {
                        XCTAssertEqual(voice.accessibilityTraits, .staticText)
                        XCTAssertEqual(voice.accessibilityValue, "Ala, jedyny głos tego silnika")
                    } else if count == 2 {
                        XCTAssertTrue(voice.accessibilityTraits.contains(.adjustable))
                        XCTAssertEqual(voice.accessibilityValue, "Ala")
                    }
                } else {
                    XCTAssertFalse(voice.isHidden)
                    XCTAssertFalse(voice.accessibilityTraits.contains(.notEnabled))
                }
            }
        }
        timings.sort()
        print(String(format: "Panel silników: %d przejść, mediana %.2f ms, maksimum %.2f ms (obsługa, układ i zatwierdzenie).",
                     timings.count, timings[timings.count / 2], try XCTUnwrap(timings.last)))
    }

    func testAkapityIPustyTekst() {
        XCTAssertEqual(SpeechReader.paragraphs("  A\nB\n\n\n\n C  "), ["A\nB", "C"])
        XCTAssertThrowsError(try SpeechReader.shared.start("  \n\n  "))
        XCTAssertEqual(SpeechReader.shared.state, .idle)
    }
    func testGlosyIPrzerwania() async throws {
        let reader = SpeechReader.shared, session = AVAudioSession.sharedInstance()
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { reader.stop(); defaults.removePersistentDomain(forName: suite) }
        let settings = SpeechPreferences(defaults)
        let text = "Czytanie sprawdzające przerwanie odtwarzania. "
        _ = try reader.start(text, settings: settings)
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: session,
                                        userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        XCTAssertEqual(reader.state, .idle)
        _ = try reader.start(text, settings: settings)
        NotificationCenter.default.post(name: AVAudioSession.routeChangeNotification, object: session,
                                        userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue])
        await Task.yield()
        XCTAssertEqual(reader.state, .idle)
    }
}

final class ElevenContractTests: XCTestCase {
    func testKatalogNieZalezyOdJezykaAniMetadanych() async throws {
        final class Pages: URLProtocol, @unchecked Sendable {
            override class func canInit(with request: URLRequest) -> Bool { true }
            override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
            override func stopLoading() {}
            override func startLoading() {
                guard let url = request.url,
                      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
                    client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                    return
                }
                let page = url.query?.contains("next_page_token=dalej") == true ? """
                {"voices":[{"voice_id":"b","name":"Mój głos","category":"cloned"},
                           {"voice_id":"c","name":"Nowy","labels":null,"verified_languages":[]},
                           {"voice_id":"a","name":"Anna"}],"has_more":false}
                """ : """
                {"voices":[{"voice_id":"a","name":"Anna","labels":{"language":"it"},"verified_languages":[{"language":"it"}]}],
                 "has_more":true,"next_page_token":"dalej"}
                """
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data(page.utf8))
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        let network = ElevenNetwork()
        network.configuration.protocolClasses = [Pages.self]
        defer { network.session.finishTasksAndInvalidate() }
        let voices = try await network.voices(key: "probny")
        XCTAssertEqual(voices.map(\.voice_id), ["a", "b", "c"])
        for voice in voices {
            let request = try ElevenNetwork.shared.speech(text: "Hej.", voice: voice.voice_id, key: "próba")
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
            XCTAssertEqual(body["language_code"] as? String, "pl")
        }
    }

    func testTekstIPodzialBezUtratyLiter() {
        let text = "# **Zażółć gęślą jaźń**\n\n[Źródło](https://example.org/x) *tekst*."
        XCTAssertEqual(ElevenText.clean(text), "Zażółć gęślą jaźń\n\nŹródło tekst.")
        XCTAssertEqual(ElevenText.chunks(ElevenText.clean(" ** ")), [])
        let long = String(repeating: "ę", count: 4001)
        XCTAssertEqual(ElevenText.chunks(long).map(\.count), [2000, 2000, 1])
        XCTAssertEqual(ElevenText.chunks(long).joined(), long)
        let prefix = String(repeating: "A", count: 1950) + "."
        let suffix = String(repeating: "ą", count: 90)
        XCTAssertEqual(ElevenText.chunks(prefix + " " + suffix), [prefix, suffix])
    }
    func testZadanieBezWysylkiIKluczCache() throws {
        let request = try ElevenNetwork.shared.speech(text: "Łaska", voice: "glos", key: "fikcyjny")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/v1/text-to-speech/glos/stream")
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(payload["model_id"] as? String, "eleven_v4")
        XCTAssertEqual(payload["language_code"] as? String, "pl")
        XCTAssertEqual(payload["text"] as? String, "Łaska")
        XCTAssertThrowsError(try ElevenNetwork.shared.speech(text: "Łaska", voice: "../inny", key: "fikcyjny"))
        let id = ElevenText.cacheID(text: "Łaska", voice: "A")
        XCTAssertNotEqual(id, ElevenText.cacheID(text: "Łaska", voice: "B"))
        XCTAssertNotEqual(id, ElevenText.cacheID(text: "Laska", voice: "A"))
    }
    func testUrwanaRamkaNieJestGotowymPlikiem() {
        var frame = Data([255, 251, 144, 0])
        frame.append(Data(repeating: 0, count: 413))
        XCTAssertTrue(ElevenMP3.complete(frame + frame))
        XCTAssertFalse(ElevenMP3.complete(frame + frame.dropLast()))
        XCTAssertFalse(ElevenMP3.complete(Data()))
        XCTAssertFalse(ElevenMP3.complete(Data("To nie jest MP3".utf8)))
    }
    func testRozneBledySerwisuBezSieci() throws {
        let url = try XCTUnwrap(URL(string: "https://example.org/"))
        for (status, code, message) in [(401, "invalid_api_key", "wygasł"), (401, "missing_permissions", "uprawnień"),
                                         (401, "quota_exceeded", "kredytów"), (429, "", "liczbę żądań"),
                                         (503, "", "503")] {
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
            let data = try JSONSerialization.data(withJSONObject: ["detail": ["status": code]])
            XCTAssertThrowsError(try ElevenNetwork.check(response, body: data)) {
                XCTAssertTrue($0.localizedDescription.contains(message))
            }
        }
        XCTAssertTrue(ElevenNetwork.message(URLError(.notConnectedToInternet)).contains("internet"))
    }
}

/// Klucz jednorazowy pochodzi z prywatnego kontenera aplikacji, nigdy z paczki testowej.
@MainActor
final class ElevenDeviceTests: XCTestCase {
    private let manager = FileManager.default
    private var documents: URL { manager.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private var restoreURL: URL { documents.appendingPathComponent(".eleven-odtworz.plist") }
    private let keys = ["silnikEleven", "glosEleven", "katalogEleven"]
    private let title = "Próba krótkiego czytania ElevenLabs"

    private func until(_ description: String, timeout: Double = 35, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { throw ReaderError(description) }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }
    private func elements(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(elements)
    }

    func testSkonfigurujKluczNaTymTelefonieNaZyczenie() async throws {
        let file = manager.temporaryDirectory.appendingPathComponent("eleven-zachowaj-na-telefonie")
        try XCTSkipUnless(manager.fileExists(atPath: file.path), "Brak jednorazowego zlecenia konfiguracji telefonu.")
        let data = try Data(contentsOf: file)
        try manager.removeItem(at: file)
        let key = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let prefs = SpeechPreferences()
        let previous = prefs.cloudSelected
        var configured = false
        defer { if !configured { prefs.cloudSelected = previous } }
        prefs.cloudSelected = true
        let screen = SettingsScreen()
        screen.loadViewIfNeeded()
        let controls = elements(screen.view)
        let field = try XCTUnwrap(controls.compactMap { $0 as? UITextField }.first { $0.isSecureTextEntry })
        let save = try XCTUnwrap(controls.compactMap { $0 as? UIButton }.first { $0.configuration?.title == "Testuj i zapisz klucz" })
        field.text = key
        save.sendActions(for: .primaryActionTriggered)
        try await until("Formularz nie zakończył sprawdzania klucza.") { save.isEnabled }
        guard field.text?.isEmpty != false, try ElevenKey.read() == key,
              prefs.cloudVoices.contains(where: { $0.voice_id == prefs.cloudVoice })
        else { throw ReaderError("Formularz nie potwierdził klucza i wyboru głosu.") }
        configured = true
        print("Pęk kluczy potwierdzony. Głosy konta na telefonie: \(prefs.cloudVoices.count). Bez syntezy.")
    }

    func testPelnyKatalogPoAktualizacjiNaZyczenie() async throws {
        // Plik jednorazowy: niezależny wykaz ID z GET /v2/voices oraz zgoda na czteroznakową próbkę.
        struct Probe: Decodable { let key: String; let ids: [String]; let chosen: String }
        let file = documents.appendingPathComponent(".eleven-katalog")
        try XCTSkipUnless(manager.fileExists(atPath: file.path), "Brak zlecenia krótkiej próby na koncie.")
        let bytes = try Data(contentsOf: file)
        try manager.removeItem(at: file)
        let probe = try JSONDecoder().decode(Probe.self, from: bytes)
        let prefs = SpeechPreferences()
        let old = keys.reduce(into: [String: Any]()) { $0[$1] = prefs.defaults.object(forKey: $1) }
        let previous = try ElevenKey.read()
        addTeardownBlock { @MainActor [keys] in
            SpeechReader.shared.leave()
            for key in keys { prefs.defaults.set(old[key], forKey: key) }
            if let previous { try ElevenKey.save(previous) } else { try ElevenKey.remove() }
        }
        try ElevenKey.save(probe.key)
        let original = try XCTUnwrap(probe.ids.first { $0 != probe.chosen })
        prefs.cloudSelected = true
        prefs.cloudVoice = original
        prefs.cloudVoices = [ElevenVoice(voice_id: original, name: "Poprzedni katalog")]
        let screen = SettingsScreen()
        screen.loadViewIfNeeded()
        screen.viewDidAppear(false)
        try await until("Nie odświeżono starego katalogu.") { prefs.cloudVoices.count == probe.ids.count }
        let catalog = prefs.cloudVoices
        XCTAssertEqual(Set(catalog.map(\.voice_id)), Set(probe.ids))
        XCTAssertEqual(prefs.cloudVoice, original)
        let slider = try XCTUnwrap(elements(screen.view).compactMap { $0 as? ChoiceSlider }.first { $0.accessibilityLabel == "Głos" })
        XCTAssertEqual(Int(slider.maximumValue) + 1, catalog.count)
        slider.value = 0
        slider.sendActions(for: .valueChanged)
        for (index, voice) in catalog.enumerated() {
            if index > 0 { slider.accessibilityIncrement() }
            XCTAssertEqual(slider.accessibilityValue, voice.name)
            XCTAssertEqual(prefs.cloudVoice, voice.voice_id)
        }
        let index = try XCTUnwrap(catalog.firstIndex { $0.voice_id == probe.chosen })
        slider.value = Float(index)
        slider.sendActions(for: .valueChanged)
        let reader = SpeechReader.shared
        _ = try reader.start("Hej.", settings: prefs)
        try await until("Nie zakończono próbki.") { reader.state == .idle }
        if let error = reader.takeCloudError() { throw ReaderError(error) }
        let id = ElevenText.cacheID(text: "Hej.", voice: probe.chosen)
        let cache = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ElevenMP3")
        let url = cache.appendingPathComponent(id + ".mp3")
        XCTAssertTrue(ElevenMP3.complete(try Data(contentsOf: url)))
        print("Pełny katalog: \(catalog.count) z \(probe.ids.count) głosów dostępnych suwakiem; próbka: \(catalog[index].name).")
    }

    func testDwieKrotkieGeneracjeNaZyczenie() async throws {
        let replayFile = documents.appendingPathComponent(".eleven-tylko-cache")
        let replay = manager.fileExists(atPath: replayFile.path)
        let file = replay ? replayFile : documents.appendingPathComponent(".eleven-jednorazowy")
        try XCTSkipUnless(manager.fileExists(atPath: file.path), "Bez jawnie dostarczonego klucza nie zamawiamy mowy.")
        let key = try String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        try manager.removeItem(at: file)
        try XCTSkipIf(ElevenBookmark.load() != nil || manager.fileExists(atPath: restoreURL.path),
                      "Nie zastępujemy istniejącej sesji czytania.")
        let defaults = UserDefaults.standard
        let old = keys.reduce(into: [String: Any]()) { $0[$1] = defaults.object(forKey: $1) }
        try PropertyListSerialization.data(fromPropertyList: old, format: .binary, options: 0)
            .write(to: restoreURL, options: [.atomic, .completeFileProtection])
        let previous = try ElevenKey.read()
        defer {
            do {
                if let previous { try ElevenKey.save(previous) } else { try ElevenKey.remove() }
            } catch { XCTFail("Nie udało się przywrócić stanu pęku kluczy.") }
        }
        let prefs = SpeechPreferences()
        prefs.cloudSelected = true
        let screen = SettingsScreen()
        screen.loadViewIfNeeded()
        let controls = elements(screen.view)
        let field = try XCTUnwrap(controls.compactMap { $0 as? UITextField }.first)
        XCTAssertTrue(field.isSecureTextEntry)
        let verify = try XCTUnwrap(controls.compactMap { $0 as? UIButton }.first { $0.configuration?.title == "Testuj i zapisz klucz" })
        field.text = "nieprawidlowy-klucz"
        verify.sendActions(for: .primaryActionTriggered)
        try await until("Nie zakończono próby błędnego klucza.") { verify.isEnabled }
        XCTAssertTrue(controls.compactMap { ($0 as? UILabel)?.text }.contains { $0.contains("błędny lub wygasł") })
        let unchanged = try ElevenKey.read() == previous
        XCTAssertTrue(unchanged, "Odrzucony klucz nie może zastąpić zapisanego.")
        field.text = key
        verify.sendActions(for: .primaryActionTriggered)
        try await until("Nie zakończono weryfikacji klucza.") { verify.isEnabled }
        guard try ElevenKey.read() == key, field.text?.isEmpty != false else {
            throw ReaderError("Klucz nie został potwierdzony przez formularz.")
        }
        let voice = try XCTUnwrap(prefs.cloudVoices.first)
        prefs.cloudVoice = voice.voice_id
        print("Katalog iPhone: \(prefs.cloudVoices.count) głosy; użyto \(voice.name).")
        let phrase = SettingsScreen.cloudSampleText
        let parts = [phrase, "Amen.", phrase]
        XCTAssertEqual(parts[0], "Pokój wam.")
        let directory = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ElevenMP3")
        let files = parts.prefix(2).map { directory.appendingPathComponent(ElevenText.cacheID(text: $0, voice: voice.voice_id) + ".mp3") }
        print("Przed odczytem gotowych unikalnych fragmentów: \(files.filter { manager.fileExists(atPath: $0.path) }.count)/2.")
        if replay {
            guard files.allSatisfy({ manager.fileExists(atPath: $0.path) }) else {
                throw ReaderError("Brak wcześniej wygenerowanych plików. Próba nie może zamawiać nagrań.")
            }
            try ElevenKey.remove()
        }
        let book = ElevenBookmark(id: UUID(), title: title, parts: parts, voice: voice.voice_id, model: ElevenNetwork.model)
        try book.save()
        let reader = SpeechReader.shared
        let text = parts.joined(separator: "\n\n")
        defer { reader.leave() }
        var began = 0
        let token = NotificationCenter.default.addObserver(forName: SpeechReader.changed, object: reader, queue: .main) { _ in
            if reader.state == .speaking { began += 1 }
        }
        defer { NotificationCenter.default.removeObserver(token) }
        _ = try reader.start(text, title: title)
        try await until("Czytnik nie zakończył pracy z prawdziwym strumieniem.", timeout: 90) { reader.state == .idle }
        if let error = reader.takeCloudError() { throw ReaderError(error) }
        XCTAssertEqual(began, 3)
        XCTAssertNil(ElevenBookmark.load())
        for url in files {
            XCTAssertTrue(ElevenMP3.complete(try Data(contentsOf: url)))
            let file = try AVAudioFile(forReading: url)
            print("Gotowy MP3: \(file.length) ramek przy \(file.processingFormat.sampleRate) Hz.")
        }

        // Brak klucza wyklucza płatne ponowienie. Korzystamy z tych samych autentycznych nagrań.
        try ElevenKey.remove()
        _ = try reader.start(phrase)
        try await until("Próbka z pamięci nie zakończyła się.") { reader.state == .idle }
        XCTAssertNil(reader.takeCloudError())
        try book.save()
        _ = try reader.start(text, title: title)
        try await until("Nie rozpoczęto wznowienia.") { reader.state == .speaking }
        try await Task.sleep(nanoseconds: 480_000_000)
        reader.pause()
        XCTAssertEqual(reader.state, .paused)
        reader.leave()
        let saved = try XCTUnwrap(ElevenBookmark.load())
        XCTAssertEqual(saved.0.id, book.id)
        XCTAssertGreaterThan(saved.1.seconds, 0)
        print("Pozostawiono sesję do próby po restarcie: fragment \(saved.1.index + 1), \(saved.1.seconds) s.")
    }

    func testMiejsceNaAutentycznymNagraniuBezPonownegoZamawiania() async throws {
        try XCTSkipUnless(manager.fileExists(atPath: restoreURL.path), "Brak przygotowanych prawdziwych nagrań.")
        let saved = try XCTUnwrap(ElevenBookmark.load())
        XCTAssertEqual(saved.0.title, title)
        let files = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ElevenMP3")
        for part in Set(saved.0.parts) {
            let url = files.appendingPathComponent(ElevenText.cacheID(text: part, voice: saved.0.voice) + ".mp3")
            guard manager.fileExists(atPath: url.path) else { throw ReaderError("Brak gotowej próbki. Nie ponowiono generacji.") }
            let audio = try AVAudioFile(forReading: url)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)))
            try audio.read(into: buffer)
            let samples = try XCTUnwrap(buffer.floatChannelData?[0])
            let peak = UnsafeBufferPointer(start: samples, count: Int(buffer.frameLength)).map { abs($0) }.max() ?? 0
            XCTAssertGreaterThan(peak, 0.01)
            print("Odczytano autentyczny sygnał mowy, amplituda szczytowa: \(peak).")
        }
        let player = SpeechReader.shared
        defer { player.leave() }
        _ = try player.start(saved.0.parts.joined(separator: "\n\n"), title: title)
        try await until("Brak startu nagrania.") { player.state == .speaking }
        try await Task.sleep(nanoseconds: 480_000_000)
        player.pause()
        XCTAssertEqual(player.state, .paused)
        let before = try XCTUnwrap(ElevenBookmark.load()).1
        try await Task.sleep(nanoseconds: 120_000_000)
        player.leave()
        let after = try XCTUnwrap(ElevenBookmark.load()).1
        XCTAssertGreaterThan(after.seconds, 0.15)
        XCTAssertEqual(before.seconds, after.seconds, accuracy: 0.01)
        print("Pauza i wyjście: fragment \(after.index + 1), zapisana pozycja \(after.seconds) s.")
    }

    func testSygnalZDekoderaPrzedKoncemPobierania() async throws {
        try XCTSkipUnless(manager.fileExists(atPath: restoreURL.path), "Brak próbek autentycznej generacji.")
        let preferences = SpeechPreferences()
        let voice = try XCTUnwrap(preferences.cloudVoice)
        let id = ElevenText.cacheID(text: SettingsScreen.cloudSampleText, voice: voice)
        let url = manager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ElevenMP3").appendingPathComponent(id + ".mp3")
        let bytes = try Data(contentsOf: url)
        XCTAssertTrue(ElevenMP3.complete(bytes))
        XCTAssertFalse(ElevenMP3.complete(bytes.dropLast()))
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setActive(true)
        defer { try? session.setActive(false, options: .notifyOthersOnDeactivation) }
        let engine = AVAudioEngine()
        let stream = try ElevenAudio(offset: 0, preferences: preferences, engine: engine)
        var attached = false
        var peak: Float = 0
        var ended = false
        stream.onStart = {
            attached = true
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
                guard let channel = buffer.floatChannelData?[0] else { return }
                let points = UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
                let amplitude = points.reduce(Float.zero) { max($0, abs($1)) }
                DispatchQueue.main.async { peak = max(peak, amplitude) }
            }
        }
        defer {
            if attached { engine.mainMixerNode.removeTap(onBus: 0) }
            stream.close()
        }
        stream.onEnd = { ended = true }
        let half = bytes.count / 2
        try stream.feed(bytes.prefix(half))
        XCTAssertTrue(attached, "Nie wystartowano przed końcem pliku.")
        try await until("Brak niezerowego sygnału na wyjściu miksera po pierwszej połowie MP3.", timeout: 4) { peak > 0.001 }
        print("Przed EOF: \(half) z \(bytes.count) bajtów, amplituda na mikserze \(peak).")
        try stream.feed(bytes.dropFirst(half))
        try stream.endOfInput()
        try await until("Brak końca odtwarzania.") { ended }
    }

    func testAnulowaniePrawdziwegoStrumieniaNaZyczenie() async throws {
        let file = documents.appendingPathComponent(".eleven-anulowanie")
        try XCTSkipUnless(manager.fileExists(atPath: file.path), "Brak osobnej zgody na próbę anulowania.")
        let key = try String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        try manager.removeItem(at: file)
        let voice = try XCTUnwrap(SpeechPreferences().cloudVoice)
        let request = try ElevenNetwork.shared.speech(text: "Tak.", voice: voice, key: key)
        let destination = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
        let download = ElevenTransfer(destination: destination)
        defer { download.cancel(); try? manager.removeItem(at: destination) }
        var received = 0
        var failure: Error?
        download.onBytes = { bytes in
            received += bytes.count
            download.cancel()
        }
        download.onFinish = { error in failure = error }
        try download.start(request)
        try await until("Nie otrzymano odpowiedzi usługi.") { received > 0 || failure != nil }
        if let failure { throw failure }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(manager.fileExists(atPath: download.partial.path))
        XCTAssertFalse(manager.fileExists(atPath: destination.path))
        print("Anulowano po odbiorze pierwszej porcji: \(received) bajtów; brak pliku roboczego i gotowego.")
    }

    func testPrzywrocPoProbieNaZyczenie() throws {
        try XCTSkipUnless(manager.fileExists(atPath: restoreURL.path), "Brak zapisu ustawień próby.")
        let saved = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: restoreURL), format: nil) as? [String: Any])
        if ElevenBookmark.load()?.0.title == title { try ElevenBookmark.clear() }
        for key in keys { UserDefaults.standard.set(saved[key], forKey: key) }
        try manager.removeItem(at: restoreURL)
    }
}
