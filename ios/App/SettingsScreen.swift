import AVFoundation
import UIKit

final class SettingsScreen: FormScreen {
    private let preferences = SpeechPreferences()
    private let voice = ChoiceSlider("Głos")
    private let rate = ChoiceSlider("Szybkość mowy")
    private let volume = ChoiceSlider("Głośność")
    private var voices: [AVSpeechSynthesisVoice] = []
    private var sample = UIButton()
    private let notice = UILabel()
    static let sampleText = "Tak brzmi wybrany głos. Możesz nim słuchać Pisma Świętego i czytań liturgicznych."

    override func configure() {
        heading("Czytanie na głos", in: choices)
        addChoice(voice) { [weak self] index in
            guard let self else { return }
            preferences.voiceID = index == 0 ? nil : voices[index - 1].identifier
            notice.text = nil
            SpeechReader.shared.stop()
        }
        addChoice(rate) { [weak self] index in self?.preferences.speed = index; SpeechReader.shared.stop() }
        addChoice(volume) { [weak self] index in self?.preferences.volume = index; SpeechReader.shared.stop() }
        notice.numberOfLines = 0
        notice.font = .preferredFont(forTextStyle: .body)
        notice.adjustsFontForContentSizeCategory = true
        choices.addArrangedSubview(notice)
        sample = button("Odsłuchaj próbkę") { [weak self] in self?.toggleSample() }
        button("Przywróć domyślną syntezę") { [weak self] in
            guard let self else { return }
            SpeechReader.shared.stop()
            preferences.reset()
            notice.text = nil
            refresh()
            UIAccessibility.post(notification: .announcement, argument: "Przywrócono domyślny głos, szybkość i głośność.")
        }
        heading("Wygląd i dostępność", in: fields)
        button("Wielkość tekstu Biblii") { [weak self] in self?.openSettings() }
        heading("O programie", in: fields)
        button("Autorzy i źródła") { [weak self] in
            let about = AboutScreen()
            about.title = "O programie"
            self?.navigationController?.pushViewController(about, animated: !UIAccessibility.isReduceMotionEnabled)
        }
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateSample), name: SpeechReader.changed, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc private func reloadVoices() { refresh() }
    override func refresh() {
        voices = SpeechPreferences.voices()
        let current = voices.firstIndex { $0.identifier == preferences.voiceID }
        if preferences.voiceID != nil && current == nil {
            preferences.voiceID = nil
            let message = "Wybrany głos nie jest już dostępny. Zastosowano głos domyślny."
            notice.text = message
            if visible { UIAccessibility.post(notification: .announcement, argument: message) }
        }
        let automatic = AVSpeechSynthesisVoice(language: "pl-PL") ?? voices.first
        let defaultName = automatic.map { "Automatyczny: " + SpeechPreferences.label($0) } ?? "Brak dostępnego głosu"
        voice.show([defaultName] + voices.map(SpeechPreferences.label), index: current.map { $0 + 1 } ?? 0)
        rate.show((0...10).map { $0 == 5 ? "6 z 11, domyślna" : "\($0 + 1) z 11" }, index: preferences.speed)
        volume.show((0...10).map { "\($0 * 10) procent" }, index: preferences.volume)
        updateSample()
    }
    @objc private func updateSample() {
        sample.configuration?.title = SpeechReader.shared.state == .idle ? "Odsłuchaj próbkę" : "Zatrzymaj próbkę"
    }
    private func toggleSample() {
        let player = SpeechReader.shared
        if player.state != .idle { player.stop(); return }
        do { if let message = try player.start(Self.sampleText) { notice.text = message } }
        catch {
            notice.text = error.localizedDescription
            UIAccessibility.post(notification: .announcement, argument: notice.text)
        }
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refresh() }
    override func viewDidDisappear(_ animated: Bool) { super.viewDidDisappear(animated); SpeechReader.shared.stop() }
}

final class AboutScreen: FormScreen {
    override func configure() {
        navigationItem.title = ""
        heading("dostępna biblia", in: choices)
        let info = Bundle.main
        let version = info.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = info.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        paragraph([version.map { "Wersja \($0)" }, build.map { "kompilacja \($0)" }].compactMap { $0 }.joined(separator: ", "))
        paragraph("Aplikacja do czytania i słuchania Pisma Świętego oraz liturgii dnia, stworzona z myślą o osobach niewidomych, słabowidzących i widzących.")
        heading("Autorzy", in: choices)
        paragraph("Aplikacja na iOS powstała na podstawie oryginalnej aplikacji na Windows.")
        paragraph("Pomysłodawca i autor wersji Windows: Grzegorz Przystupa")
        paragraph("Projektant wersji iOS: Mieczysław Bąk")
        link("Kod źródłowy oryginalnej wersji Windows na GitHubie", "https://github.com/puszkin-dev/dostepna-biblia/")
        heading("Źródła i prawa do tekstów", in: choices)
        paragraph("Czytania liturgiczne i teksty pobierane są z serwisu TwojaBiblia.pl. Przekład: Biblia Tysiąclecia, wydanie V. Prawa do tekstu przekładu: Wydawnictwo Pallottinum w Poznaniu.")
        link("Informacja wydawcy o prawach do przekładu", "https://biblia.pl/informacje-o-wydaniu/")
    }
    private func paragraph(_ text: String) {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BookStyle.ink
        choices.addArrangedSubview(label)
        choices.setCustomSpacing(12, after: label)
    }
    private func link(_ title: String, _ address: String) {
        guard let url = URL(string: address) else { return }
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleAlignment = .leading
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in UIApplication.shared.open(url) })
        button.accessibilityTraits = .link
        button.contentHorizontalAlignment = .leading
        addControl(button, to: choices)
    }
}
