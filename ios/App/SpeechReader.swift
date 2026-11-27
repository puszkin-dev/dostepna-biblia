import AVFoundation
import MediaPlayer
import UIKit

struct SpeechPreferences {
    static let rates: [Float] = (0...10).map { step in
        let normal = AVSpeechUtteranceDefaultSpeechRate
        if step <= 5 { return normal - (normal - AVSpeechUtteranceMinimumSpeechRate) * Float(5 - step) / 5 }
        return normal + (AVSpeechUtteranceMaximumSpeechRate - normal) * Float(step - 5) / 5
    }
    let defaults: UserDefaults
    init(_ defaults: UserDefaults = .standard) { self.defaults = defaults }
    private func index(_ key: String, standard: Int) -> Int {
        guard let value = defaults.object(forKey: key) as? Int, (0...10).contains(value) else { return standard }
        return value
    }
    var speed: Int {
        get { index("tempoMowy", standard: 5) }
        nonmutating set { defaults.set(min(10, max(0, newValue)), forKey: "tempoMowy") }
    }
    var volume: Int {
        get { index("glosnoscMowy", standard: 10) }
        nonmutating set { defaults.set(min(10, max(0, newValue)), forKey: "glosnoscMowy") }
    }
    var voiceID: String? {
        get { defaults.string(forKey: "glosMowy") }
        nonmutating set { defaults.set(newValue, forKey: "glosMowy") }
    }
    func reset() {
        for key in ["tempoMowy", "glosnoscMowy", "glosMowy"] { defaults.removeObject(forKey: key) }
    }
    static func voices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().sorted {
            let a = $0.language.hasPrefix("pl"), b = $1.language.hasPrefix("pl")
            if a != b { return a }
            if $0.language != $1.language { return $0.language < $1.language }
            if $0.quality != $1.quality { return $0.quality.rawValue > $1.quality.rawValue }
            return ($0.name, $0.identifier) < ($1.name, $1.identifier)
        }
    }
    static func label(_ voice: AVSpeechSynthesisVoice) -> String {
        let locale = Locale(identifier: "pl")
        let language = locale.localizedString(forIdentifier: voice.language)
            ?? locale.localizedString(forLanguageCode: String(voice.language.prefix(2))) ?? voice.language
        let quality = voice.quality == .premium ? "premium" : voice.quality == .enhanced ? "rozszerzony" : ""
        let suffix = quality.isEmpty || voice.name.localizedCaseInsensitiveContains(quality) ? "" : ", " + quality
        return "\(voice.name), \(language)\(suffix)"
    }
}

/// Jedna kolejka na całą aplikację. W tle pozostaje wyłącznie odczyt otwartego tekstu.
final class SpeechReader: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechReader()
    static let changed = Notification.Name("ZmianaOdczytu")
    enum State { case idle, preparing, speaking, paused }
    private(set) var state = State.idle {
        didSet {
            updateNowPlaying()
            NotificationCenter.default.post(name: Self.changed, object: self)
        }
    }
    private let synth = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()
    private var last: AVSpeechUtterance?
    private var active = Set<ObjectIdentifier>()
    private var readingTitle: String?
    private override init() {
        super.init()
        synth.delegate = self
        synth.usesApplicationAudioSession = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(interrupted), name: AVAudioSession.interruptionNotification, object: session)
        center.addObserver(self, selector: #selector(routeChanged), name: AVAudioSession.routeChangeNotification, object: session)
        center.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(stop), name: AVAudioSession.mediaServicesWereResetNotification, object: session)
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget(self, action: #selector(remotePlay))
        commands.pauseCommand.addTarget(self, action: #selector(remotePause))
        commands.stopCommand.addTarget(self, action: #selector(remoteStop))
        commands.togglePlayPauseCommand.addTarget(self, action: #selector(remoteToggle))
        updateNowPlaying()
    }
    static func paragraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    func start(_ text: String, title: String? = nil, settings: SpeechPreferences = SpeechPreferences()) throws -> String? {
        stop()
        let parts = Self.paragraphs(text)
        guard !parts.isEmpty else { throw ReaderError("Brak tekstu do przeczytania.") }
        let chosen = settings.voiceID.flatMap(AVSpeechSynthesisVoice.init(identifier:))
        let fallback = chosen == nil && settings.voiceID != nil
        guard let voice = chosen ?? AVSpeechSynthesisVoice(language: "pl-PL") ?? SpeechPreferences.voices().first else {
            throw ReaderError("Brak dostępnego głosu. Pobierz głos w ustawieniach mowy iPhone’a.")
        }
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: title == nil ? [.mixWithOthers] : [])
            try session.setActive(true)
        } catch { throw ReaderError("Nie można teraz odtwarzać mowy. Spróbuj po zakończeniu innego odtwarzania.") }
        if fallback { settings.voiceID = nil }
        let queue = parts.map { part in
            let item = AVSpeechUtterance(string: part)
            item.voice = voice
            item.rate = SpeechPreferences.rates[settings.speed]
            item.volume = Float(settings.volume) / 10
            item.postUtteranceDelay = 0.16
            return item
        }
        last = queue.last
        active = Set(queue.map(ObjectIdentifier.init))
        readingTitle = title
        state = .preparing
        queue.forEach(synth.speak)
        return fallback ? "Wybrany głos nie jest już dostępny. Teraz czyta \(voice.name)." : nil
    }
    func pause() {
        guard state == .speaking, synth.pauseSpeaking(at: .immediate) else { return }
        state = .paused
    }
    func resume() {
        guard state == .paused else { return }
        do { try session.setActive(true) } catch { stop(); return }
        if synth.continueSpeaking() { state = .speaking }
    }
    @objc func stop() {
        guard last != nil else { return }
        last = nil
        active.removeAll()
        synth.stopSpeaking(at: .immediate)
        finish()
    }
    private func finish() {
        last = nil
        active.removeAll()
        readingTitle = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        state = .idle
    }
    @objc private func enteredBackground() { if readingTitle == nil { stop() } }
    private func updateNowPlaying() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.isEnabled = readingTitle != nil && state == .paused
        commands.pauseCommand.isEnabled = readingTitle != nil && state == .speaking
        commands.stopCommand.isEnabled = readingTitle != nil && state != .idle
        commands.togglePlayPauseCommand.isEnabled = commands.playCommand.isEnabled || commands.pauseCommand.isEnabled
        if let readingTitle {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: readingTitle,
                MPMediaItemPropertyArtist: "dostępna biblia",
                MPNowPlayingInfoPropertyPlaybackRate: state == .speaking ? 1.0 : 0.0
            ]
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
    @objc private func remotePlay(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard readingTitle != nil, state == .paused else { return .noActionableNowPlayingItem }
        resume()
        return state == .speaking ? .success : .commandFailed
    }
    @objc private func remotePause(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard readingTitle != nil, state == .speaking else { return .noActionableNowPlayingItem }
        pause()
        return state == .paused ? .success : .commandFailed
    }
    @objc private func remoteToggle(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        state == .paused ? remotePlay(event) : remotePause(event)
    }
    @objc private func remoteStop(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard readingTitle != nil else { return .noActionableNowPlayingItem }
        stop()
        return .success
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if active.contains(ObjectIdentifier(utterance)), state == .preparing { state = .speaking }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        active.remove(ObjectIdentifier(utterance))
        if utterance === last { finish() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if active.contains(ObjectIdentifier(utterance)) { stop() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        if active.contains(ObjectIdentifier(utterance)), synth.isPaused { state = .paused }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        if active.contains(ObjectIdentifier(utterance)), !synth.isPaused { state = .speaking }
    }
    @objc private func interrupted(_ note: Notification) {
        if note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == AVAudioSession.InterruptionType.began.rawValue { stop() }
    }
    @objc private func routeChanged(_ note: Notification) {
        if note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
            DispatchQueue.main.async { self.stop() }
        }
    }
}
