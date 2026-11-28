import AVFoundation
import MediaPlayer
import UIKit

struct SpeechPreferences {
    static let step = 5
    static let percentages = Array(stride(from: 0, through: 100, by: step))
    let defaults: UserDefaults
    init(_ defaults: UserDefaults = .standard) { self.defaults = defaults }

    private func percentage(_ key: String, legacy: String, standard: Int) -> Int {
        if let saved = defaults.object(forKey: key) {
            guard let value = saved as? Int, Self.percentages.contains(value) else { return standard }
            return value
        }
        // Poprzednie wydanie zapisywało indeks 0…10, a nie liczbę procentów.
        guard let index = defaults.object(forKey: legacy) as? Int, (0...10).contains(index) else { return standard }
        return index * 10
    }

    var speed: Int {
        get { percentage("tempoProcent", legacy: "tempoMowy", standard: 50) }
        nonmutating set { defaults.set(Self.nearestPercent(newValue), forKey: "tempoProcent") }
    }
    var volume: Int {
        get { percentage("glosnoscProcent", legacy: "glosnoscMowy", standard: 100) }
        nonmutating set { defaults.set(Self.nearestPercent(newValue), forKey: "glosnoscProcent") }
    }
    private static func nearestPercent(_ value: Int) -> Int {
        ((min(100, max(0, value)) + step / 2) / step) * step
    }

    func utterance(_ text: String, voice: AVSpeechSynthesisVoice) -> AVSpeechUtterance {
        let item = AVSpeechUtterance(string: text)
        item.voice = voice
        item.prefersAssistiveTechnologySettings = false
        let range = AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate
        item.rate = AVSpeechUtteranceMinimumSpeechRate + range * Float(speed) / 100
        item.volume = Float(volume) / 100
        item.postUtteranceDelay = 0.16
        return item
    }
    var voiceID: String? {
        get { defaults.string(forKey: "glosMowy") }
        nonmutating set { defaults.set(newValue, forKey: "glosMowy") }
    }
    var cloudSelected: Bool {
        get { defaults.bool(forKey: "silnikEleven") }
        nonmutating set { defaults.set(newValue, forKey: "silnikEleven") }
    }
    var cloudVoice: String? {
        get { defaults.string(forKey: "glosEleven") }
        nonmutating set { defaults.set(newValue, forKey: "glosEleven") }
    }
    var cloudVoices: [ElevenVoice] {
        get {
            guard let data = defaults.data(forKey: "katalogEleven") else { return [] }
            return (try? JSONDecoder().decode([ElevenVoice].self, from: data)) ?? []
        }
        nonmutating set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "katalogEleven") }
    }
    func reset() {
        cloudSelected = false
        for key in ["tempoProcent", "glosnoscProcent", "tempoMowy", "glosnoscMowy", "glosMowy"] { defaults.removeObject(forKey: key) }
    }
}

/// Katalog AVFoundation obejmuje różne silniki, języki i jakości tego samego głosu.
struct VoiceGroup {
    let name: String
    let voices: [AVSpeechSynthesisVoice]
    let labels: [String]

    private static func engine(_ id: String) -> String {
        let prefix = id.lowercased()
        if prefix.hasPrefix("dj.phoenix.espeak-ng.") { return "eSpeak NG" }
        if prefix.hasPrefix("pl.syntalk.research.") { return "SynTalk" }
        if prefix.hasPrefix("com.axel.rhvoice-ee.") { return "RHVoice EE" }
        if prefix.hasPrefix("pl.speak.ireadboard.") { return "IReadboard" }
        if prefix.hasPrefix("com.apple.eloquence.") { return "Eloquence" }
        if prefix.hasPrefix("com.apple.") { return "Apple" }
        let domain = id.split(separator: ".").dropLast()
        return domain.isEmpty ? id : domain.joined(separator: ".")
    }

    private static func label(_ voice: AVSpeechSynthesisVoice) -> String {
        let quality = voice.quality == .premium ? "premium" : voice.quality == .enhanced ? "rozszerzony" : ""
        return quality.isEmpty || voice.name.localizedCaseInsensitiveContains(quality)
            ? voice.name : "\(voice.name), \(quality)"
    }

    static func isPolish(_ language: String) -> Bool {
        language.split(whereSeparator: { $0 == "-" || $0 == "_" }).first?.lowercased() == "pl"
    }

    static func automatic(in groups: [VoiceGroup]) -> AVSpeechSynthesisVoice? {
        if let system = AVSpeechSynthesisVoice(language: "pl-PL"),
           groups.contains(where: { $0.voices.contains { $0.identifier == system.identifier } }) {
            return system
        }
        return groups.first?.voices.first
    }

    static func catalog(_ source: [AVSpeechSynthesisVoice]) -> [VoiceGroup] {
        var identifiers = Set<String>()
        let unique = source.filter { isPolish($0.language) && identifiers.insert($0.identifier).inserted }
        let groups = Dictionary(grouping: unique) { engine($0.identifier) }
        return groups.map { name, members in
            let voices = members.sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.identifier < $1.identifier : order == .orderedAscending
            }
            let names = voices.map(label)
            let counts = Dictionary(grouping: names, by: { $0.lowercased() })
            let labels = zip(voices, names).map { voice, name in
                counts[name.lowercased()]?.count == 1 ? name : "\(name), \(voice.identifier)"
            }
            return VoiceGroup(name: name, voices: voices, labels: labels)
        }.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
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
    private var cloud: ElevenPlayback?
    private var cloudError: String?
    func takeCloudError() -> String? {
        defer { cloudError = nil }
        return cloudError
    }
    private let synth = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()
    private var last: AVSpeechUtterance?
    private var active = Set<ObjectIdentifier>()
    var isSample: Bool { readingTitle == nil }
    private var readingTitle: String?
    private override init() {
        super.init()
        synth.delegate = self
        synth.usesApplicationAudioSession = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(interrupted), name: AVAudioSession.interruptionNotification, object: session)
        center.addObserver(self, selector: #selector(routeChanged), name: AVAudioSession.routeChangeNotification, object: session)
        center.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(leave), name: AVAudioSession.mediaServicesWereResetNotification, object: session)
        center.addObserver(self, selector: #selector(leave), name: UIApplication.willTerminateNotification, object: nil)
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
    func start(_ text: String, title: String? = nil, settings: SpeechPreferences = SpeechPreferences(),
               fromBeginning: Bool = false) throws -> String? {
        leave()
        cloudError = nil
        if settings.cloudSelected {
            try startCloud(text, title: title, settings: settings, fromBeginning: fromBeginning)
            return nil
        }
        let parts = Self.paragraphs(text)
        guard !parts.isEmpty else { throw ReaderError("Brak tekstu do przeczytania.") }
        let identifier = settings.voiceID
        let groups = VoiceGroup.catalog(AVSpeechSynthesisVoice.speechVoices())
        let chosen = groups.lazy.flatMap(\.voices).first { $0.identifier == identifier }
        let fallback = chosen == nil && identifier != nil
        guard let voice = chosen ?? VoiceGroup.automatic(in: groups) else {
            throw ReaderError("Brak polskiego głosu. Pobierz polski głos w ustawieniach mowy iPhone’a.")
        }
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: title == nil ? [.mixWithOthers] : [])
            try session.setActive(true)
        } catch { throw ReaderError("Nie można teraz odtwarzać mowy. Spróbuj po zakończeniu innego odtwarzania.") }
        if fallback { settings.voiceID = nil }
        let queue = parts.map { settings.utterance($0, voice: voice) }
        last = queue.last
        active = Set(queue.map(ObjectIdentifier.init))
        readingTitle = title
        state = .preparing
        queue.forEach(synth.speak)
        return fallback ? "Poprzedni głos nie jest dostępny wśród polskich głosów. Teraz czyta \(voice.name)." : nil
    }
    private func startCloud(_ text: String, title: String?, settings: SpeechPreferences, fromBeginning: Bool) throws {
        let parts = ElevenText.chunks(ElevenText.clean(text))
        guard !parts.isEmpty else { throw ReaderError("Brak tekstu do przeczytania.") }
        let saved = title != nil && !fromBeginning ? ElevenBookmark.load() : nil
        let book: ElevenBookmark
        let index: Int
        let seconds: Double
        if let (previous, cursor) = saved, previous.title == title, (previous.parts == parts || previous.parts.joined(separator: "\n\n") == text) {
            book = previous
            index = cursor.index
            seconds = cursor.seconds
        } else {
            guard let voice = settings.cloudVoice else { throw ReaderError("Najpierw zapisz klucz i wybierz głos Eleven Labs w Ustawieniach.") }
            book = ElevenBookmark(id: UUID(), title: title ?? "Próbka", parts: parts, voice: voice, model: ElevenNetwork.model)
            index = 0
            seconds = 0
        }
        let playback = try ElevenPlayback(book: book, index: index, seconds: seconds, remember: title != nil, settings: settings)
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: title == nil ? [.mixWithOthers] : [])
            try session.setActive(true)
            cloud = playback
            readingTitle = title
            state = .preparing
            playback.preparing = { [weak self] in self?.state = .preparing }
            playback.started = { [weak self] in self?.state = .speaking }
            playback.finished = { [weak self] error in
                guard let self else { return }
                cloudError = error.map(ElevenNetwork.message)
                cloud = nil
                let announcement = cloudError
                finish()
                if let announcement { UIAccessibility.post(notification: .announcement, argument: announcement) }
            }
            try playback.start()
        } catch {
            try? playback.stop(keep: true)
            cloud = nil
            finish()
            throw ReaderError(ElevenNetwork.message(error))
        }
    }
    func pause() {
        if let cloud, state == .speaking { cloud.pause(); if self.cloud != nil { state = .paused }; return }
        guard state == .speaking, synth.pauseSpeaking(at: .immediate) else { return }
        state = .paused
    }
    func resume() {
        guard state == .paused else { return }
        do { try session.setActive(true) } catch { leave(); return }
        if let cloud {
            do { try cloud.resume(); state = .speaking }
            catch { cloudError = "Nie można wznowić odtwarzania."; leave() }
            return
        }
        if synth.continueSpeaking() { state = .speaking }
    }
    @objc func stop() { end(keep: false) }
    @objc func leave() { end(keep: true) }
    private func end(keep: Bool) {
        if let cloud {
            do { try cloud.stop(keep: keep) }
            catch { cloudError = "Nie udało się zapisać zmiany sesji." }
            self.cloud = nil
            finish()
            return
        }
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
    @objc private func enteredBackground() { if readingTitle == nil { leave() } else { cloud?.checkpoint() } }
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
        if note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == AVAudioSession.InterruptionType.began.rawValue { leave() }
    }
    @objc private func routeChanged(_ note: Notification) {
        if note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
            DispatchQueue.main.async { self.leave() }
        }
    }
}
