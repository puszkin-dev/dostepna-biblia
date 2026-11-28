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
    func testAkapityIPustyTekst() {
        XCTAssertEqual(SpeechReader.paragraphs("  A\nB\n\n\n\n C  "), ["A\nB", "C"])
        XCTAssertThrowsError(try SpeechReader.shared.start("  \n\n  "))
        XCTAssertEqual(SpeechReader.shared.state, .idle)
    }
    func testGlosyIPrzerwania() async throws {
        let reader = SpeechReader.shared, session = AVAudioSession.sharedInstance()
        defer { reader.stop() }
        let text = "Czytanie sprawdzające przerwanie odtwarzania. "
        _ = try reader.start(text)
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: session,
                                        userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        XCTAssertEqual(reader.state, .idle)
        _ = try reader.start(text)
        NotificationCenter.default.post(name: AVAudioSession.routeChangeNotification, object: session,
                                        userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue])
        await Task.yield()
        XCTAssertEqual(reader.state, .idle)
    }
}
