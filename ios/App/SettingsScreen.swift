import AVFoundation
import UIKit

final class SettingsScreen: FormScreen {
    private let preferences = SpeechPreferences()
    private let group = ChoiceSlider("Silnik mowy")
    private let voice = ChoiceSlider("Głos")
    private let rate = ChoiceSlider("Szybkość mowy")
    private let volume = ChoiceSlider("Głośność")
    private var groups: [VoiceGroup] = []
    private var automaticGroup = 0
    private var selectedGroup = 0
    private var sample = UIButton()
    private let notice = UILabel()
    static let sampleText = "Tak brzmi wybrany głos. Możesz nim słuchać Pisma Świętego i czytań liturgicznych."

    override func configure() {
        heading("Czytanie na głos", in: choices)
        addChoice(group) { [weak self] index in
            guard let self, groups.indices.contains(index), index != selectedGroup else { return }
            selectVoice(index == automaticGroup ? nil : groups[index].voices.first?.identifier)
            showGroup(index)
        }
        addChoice(voice) { [weak self] index in
            guard let self, groups.indices.contains(selectedGroup) else { return }
            let offset = selectedGroup == automaticGroup ? 1 : 0
            selectVoice(index < offset ? nil : groups[selectedGroup].voices[index - offset].identifier)
        }
        addChoice(rate) { [weak self] index in
            self?.preferences.speed = SpeechPreferences.percentages[index]
            SpeechReader.shared.stop()
        }
        addChoice(volume) { [weak self] index in
            self?.preferences.volume = SpeechPreferences.percentages[index]
            SpeechReader.shared.stop()
        }
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
        heading("Pomoc i prywatność", in: fields)
        for (title, address) in [
            ("Pomoc i kontakt", "https://axelek.pl/dostepna-biblia.html#pomoc"),
            ("Polityka prywatności", "https://axelek.pl/dostepna-biblia-prywatnosc.html")
        ] {
            button(title) {
                if let url = URL(string: address) { UIApplication.shared.open(url) }
            }.accessibilityTraits = .link
        }
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateSample), name: SpeechReader.changed, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc private func reloadVoices() { refresh() }
    override func refresh() {
        groups = VoiceGroup.catalog(AVSpeechSynthesisVoice.speechVoices())
        let automatic = VoiceGroup.automatic(in: groups)?.identifier
        automaticGroup = groupIndex(for: automatic) ?? 0
        let current = groupIndex(for: preferences.voiceID)
        if preferences.voiceID != nil && current == nil && !groups.isEmpty {
            preferences.voiceID = nil
            let message = "Poprzedni głos nie jest dostępny wśród polskich głosów. Zastosowano głos domyślny."
            notice.text = message
            if visible { UIAccessibility.post(notification: .announcement, argument: message) }
        }
        let index = current ?? automaticGroup
        group.show(groups.map(\.name), index: index)
        showGroup(index)
        let percentages = SpeechPreferences.percentages
        let labels = percentages.map { "\($0) procent" }
        rate.show(labels, index: preferences.speed / SpeechPreferences.step)
        volume.show(labels, index: preferences.volume / SpeechPreferences.step)
        updateSample()
    }

    private func groupIndex(for identifier: String?) -> Int? {
        guard let identifier else { return nil }
        return groups.firstIndex { $0.voices.contains { $0.identifier == identifier } }
    }

    private func showGroup(_ index: Int) {
        selectedGroup = index
        guard groups.indices.contains(index) else {
            showVoices(["Brak polskiego głosu"], index: 0)
            return
        }
        let entry = groups[index]
        let extra = index == automaticGroup ? ["Automatyczny"] : []
        let position = entry.voices.firstIndex { $0.identifier == preferences.voiceID }
        showVoices(extra + entry.labels, index: position.map { $0 + extra.count } ?? 0)
    }

    private func showVoices(_ names: [String], index: Int) {
        voice.show(names, index: index)
        // Jedyny głos jest już wybrany, a nie niedostępny.
        let single = names.count == 1
        voice.isHidden = single
        voice.caption.accessibilityElementsHidden = !single
        voice.caption.isAccessibilityElement = single
        voice.caption.accessibilityLabel = "Głos"
        if single {
            voice.caption.accessibilityValue = groups.isEmpty ? "Brak polskiego głosu" : "\(names[index]), jedyny głos tego silnika"
        }
    }

    private func selectVoice(_ identifier: String?) {
        preferences.voiceID = identifier
        notice.text = nil
        SpeechReader.shared.stop()
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
