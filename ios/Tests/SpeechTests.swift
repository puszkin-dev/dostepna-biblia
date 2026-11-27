import AVFoundation
import XCTest
@testable import Biblia

@MainActor
final class SpeechTests: XCTestCase {
    func testUstawieniaGraniceUszkodzenieIReset() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let p = SpeechPreferences(defaults)
        XCTAssertEqual(p.speed, 5)
        XCTAssertEqual(p.volume, 10)
        p.speed = -1
        p.volume = 12
        XCTAssertEqual(p.speed, 0)
        XCTAssertEqual(p.volume, 10)
        defaults.set("uszkodzone", forKey: "tempoMowy")
        defaults.set(99, forKey: "glosnoscMowy")
        XCTAssertEqual(p.speed, 5)
        XCTAssertEqual(p.volume, 10)
        p.voiceID = "brak-takiego-głosu"
        let reader = SpeechReader.shared
        defer { reader.stop() }
        XCTAssertNotNil(try reader.start("Sprawdzenie zastępczego głosu.", settings: p))
        XCTAssertNil(p.voiceID)
        reader.stop()
        p.reset()
        XCTAssertEqual(SpeechPreferences.rates.first, AVSpeechUtteranceMinimumSpeechRate)
        XCTAssertEqual(SpeechPreferences.rates[5], AVSpeechUtteranceDefaultSpeechRate)
        XCTAssertEqual(SpeechPreferences.rates.last, AVSpeechUtteranceMaximumSpeechRate)
    }
    func testAkapityIPustyTekst() {
        XCTAssertEqual(SpeechReader.paragraphs("  A\nB\n\n\n\n C  "), ["A\nB", "C"])
        XCTAssertThrowsError(try SpeechReader.shared.start("  \n\n  "))
        XCTAssertEqual(SpeechReader.shared.state, .idle)
    }
    func testGlosyIPrzerwania() async throws {
        let reader = SpeechReader.shared, session = AVAudioSession.sharedInstance()
        defer { reader.stop() }
        let voices = SpeechPreferences.voices()
        XCTAssertFalse(voices.isEmpty)
        print("Głosy polskie: " + voices.filter { $0.language.hasPrefix("pl") }.map(SpeechPreferences.label).joined(separator: "; "))
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
