import AVFoundation
import UIKit

final class SettingsScreen: FormScreen {
    private let preferences = SpeechPreferences()
    private let group = ChoiceSlider("Silnik mowy")
    private let cloudBox = UIStackView()
    private let apiKey = UITextField()
    private var verify = UIButton()
    private var forget = UIButton()
    private var continueBook = UIButton()
    private var checking: Task<Void, Never>?
    private let voice = VoiceChoiceSlider()
    private let rate = ChoiceSlider("Szybkość mowy")
    private let volume = ChoiceSlider("Głośność")
    private var groups: [VoiceGroup] = []
    private var catalog: [ElevenVoice] = []
    private var bookmarkTitle: String?
    private var automaticGroup = 0
    private var selectedGroup = 0
    private var sample = UIButton()
    private let notice = UILabel()
    static let cloudSampleText = "Pokój wam."
    static let sampleText = "Tak brzmi wybrany głos. Możesz nim słuchać Pisma Świętego i czytań liturgicznych."

    override func configure() {
        heading("Czytanie na głos", in: choices)
        addChoice(group) { [weak self] index in
            guard let self, index != selectedGroup else { return }
            cancelValidation()
            apiKey.text = nil
            apiKey.resignFirstResponder()
            SpeechReader.shared.leave()
            selectedGroup = index
            preferences.cloudSelected = index == max(1, groups.count)
            notice.text = nil
            if groups.indices.contains(index) {
                preferences.voiceID = index == automaticGroup ? nil : groups[index].voices.first?.identifier
            }
            UIView.performWithoutAnimation {
                self.updateEngineOptions()
                self.publishLayout()
            }
            refreshCloudCatalog()
        }
        addChoice(voice) { [weak self] index in
            guard let self else { return }
            if preferences.cloudSelected {
                guard catalog.indices.contains(index) else { return }
                SpeechReader.shared.leave()
                preferences.cloudVoice = catalog[index].voice_id
                updateSample()
                return
            }
            guard groups.indices.contains(selectedGroup) else { return }
            let offset = selectedGroup == automaticGroup ? 1 : 0
            selectVoice(index < offset ? nil : groups[selectedGroup].voices[index - offset].identifier)
        }
        addChoice(rate) { [weak self] index in
            self?.preferences.speed = SpeechPreferences.percentages[index]
            SpeechReader.shared.leave()
        }
        addChoice(volume) { [weak self] index in
            self?.preferences.volume = SpeechPreferences.percentages[index]
            SpeechReader.shared.leave()
        }
        configureCloud()
        notice.numberOfLines = 0
        notice.font = .preferredFont(forTextStyle: .body)
        notice.adjustsFontForContentSizeCategory = true
        choices.addArrangedSubview(notice)
        sample = button("Odsłuchaj próbkę") { [weak self] in self?.toggleSample() }
        button("Przywróć domyślną syntezę") { [weak self] in
            guard let self else { return }
            SpeechReader.shared.leave()
            cancelValidation()
            apiKey.text = nil
            preferences.reset()
            notice.text = nil
            refresh()
            UIAccessibility.post(notification: .announcement, argument: "Przywrócono domyślny głos, szybkość i głośność.")
        }
        continueBook = button("Wznów ostatnie czytanie Eleven Labs") { [weak self] in
            guard let self, let (book, _) = ElevenBookmark.load() else { return }
            let saved = Reading(name: book.title, text: book.parts.joined(separator: "\n\n"))
            let reader = TextScreen(reading: saved)
            reader.onSave = { [weak self] in self?.export(saved) }
            reader.resumeOnOpen = true
            navigationController?.pushViewController(reader, animated: !UIAccessibility.isReduceMotionEnabled)
        }
        continueBook.accessibilityIdentifier = "wznowOstatniaSesje"
        continueBook.accessibilityLabel = "Wznów ostatnie czytanie Eleven Labs"
        heading("Wygląd i dostępność", in: fields)
        button(ReadingSize.settingName) { [weak self] in self?.openSettings() }
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
        loadLocalCatalog()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateSample), name: SpeechReader.changed, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(reloadVoices), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    @objc private func reloadVoices() {
        loadLocalCatalog()
        refresh()
        publishLayout()
    }

    private func loadLocalCatalog() {
        groups = VoiceGroup.catalog(AVSpeechSynthesisVoice.speechVoices())
        let automatic = VoiceGroup.automatic(in: groups)?.identifier
        automaticGroup = groupIndex(for: automatic) ?? 0
    }

    override func refresh() {
        catalog = preferences.cloudVoices
        bookmarkTitle = ElevenBookmark.load()?.0.title
        forget.isHidden = (try? ElevenKey.read()) == nil
        let current = groupIndex(for: preferences.voiceID)
        if preferences.voiceID != nil && current == nil && !groups.isEmpty {
            preferences.voiceID = nil
            let message = "Poprzedni głos nie jest dostępny wśród polskich głosów. Zastosowano głos domyślny."
            notice.text = message
            if visible { UIAccessibility.post(notification: .announcement, argument: message) }
        }
        let cloud = preferences.cloudSelected
        let localNames = groups.isEmpty ? ["Głos iPhone’a niedostępny"] : groups.map(\.name)
        selectedGroup = cloud ? localNames.count : current ?? automaticGroup
        group.show(localNames + ["Eleven Labs — naturalne głosy neuronowe"], index: selectedGroup)
        updateEngineOptions()
        let percentages = SpeechPreferences.percentages
        let labels = percentages.map { "\($0) procent" }
        rate.show(labels, index: preferences.speed / SpeechPreferences.step)
        volume.show(labels, index: preferences.volume / SpeechPreferences.step)
    }

    private func updateEngineOptions() {
        let cloud = preferences.cloudSelected
        cloudBox.isHidden = !cloud
        continueBook.isHidden = !cloud || bookmarkTitle == nil
        continueBook.configuration?.subtitle = bookmarkTitle
        continueBook.accessibilityValue = bookmarkTitle
        if cloud {
            let selected = preferences.cloudVoice
            let position = catalog.firstIndex { $0.voice_id == selected } ?? 0
            if catalog.isEmpty {
                let title = forget.isHidden ? "Wpisz klucz API Eleven Labs" : "Sprawdź klucz i pobierz głosy Eleven Labs"
                voice.offer(title) { [weak self] in self?.editKey() }
            } else {
                voice.present(catalog.map(\.name), index: position)
            }
        } else {
            showGroup(selectedGroup)
        }
        updateSample()
    }

    private func editKey() {
        view.layoutIfNeeded()
        apiKey.becomeFirstResponder()
        if let scroll = fields.superview as? UIScrollView {
            scroll.scrollRectToVisible(apiKey.convert(apiKey.bounds, to: scroll).insetBy(dx: 0, dy: -12), animated: false)
        }
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: apiKey)
        }
    }

    private func publishLayout() {
        guard visible else { return }
        view.layoutIfNeeded()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    private func groupIndex(for identifier: String?) -> Int? {
        guard let identifier else { return nil }
        return groups.firstIndex { $0.voices.contains { $0.identifier == identifier } }
    }

    private func showGroup(_ index: Int) {
        guard groups.indices.contains(index) else {
            voice.inform("Brak polskiego głosu")
            return
        }
        let entry = groups[index]
        let extra = index == automaticGroup ? ["Automatyczny"] : []
        let selected = preferences.voiceID
        let position = entry.voices.firstIndex { $0.identifier == selected }
        voice.present(extra + entry.labels, index: position.map { $0 + extra.count } ?? 0)
    }

    private func selectVoice(_ identifier: String?) {
        preferences.voiceID = identifier
        notice.text = nil
        SpeechReader.shared.leave()
    }

    private func configureCloud() {
        cloudBox.axis = .vertical
        cloudBox.spacing = 8
        choices.addArrangedSubview(cloudBox)
        let hint = UILabel()
        hint.numberOfLines = 0
        hint.font = .preferredFont(forTextStyle: .body)
        hint.adjustsFontForContentSizeCategory = true
        hint.text = "Eleven Labs otrzyma tekst, żeby przeczytać go po polsku. Odczyt i polska próbka korzystają z kredytów Twojego konta. Sprawdzenie klucza pobiera tylko listę głosów."
        apiKey.borderStyle = .roundedRect
        apiKey.isSecureTextEntry = true
        let keyLabel = UILabel()
        keyLabel.text = "Klucz API Eleven Labs"
        keyLabel.font = .preferredFont(forTextStyle: .headline)
        keyLabel.adjustsFontForContentSizeCategory = true
        keyLabel.numberOfLines = 0
        keyLabel.isAccessibilityElement = false
        keyLabel.accessibilityElementsHidden = true
        cloudBox.addArrangedSubview(keyLabel)
        apiKey.accessibilityLabel = "Klucz API Eleven Labs"
        apiKey.font = .preferredFont(forTextStyle: .body)
        apiKey.adjustsFontForContentSizeCategory = true
        apiKey.autocapitalizationType = .none
        apiKey.autocorrectionType = .no
        apiKey.spellCheckingType = .no
        apiKey.keyboardType = .asciiCapable
        apiKey.returnKeyType = .done
        apiKey.addAction(UIAction { [weak self] _ in self?.validateKey() }, for: .editingDidEndOnExit)
        addControl(apiKey, to: cloudBox)
        cloudBox.addArrangedSubview(hint)
        verify = button("Testuj i zapisz klucz", in: cloudBox) { [weak self] in self?.validateKey() }
        forget = button("Usuń zapisany klucz", in: cloudBox) { [weak self] in self?.forgetKey() }
    }
    private func report(_ text: String) {
        notice.text = text
        if visible { UIAccessibility.post(notification: .announcement, argument: text) }
    }
    private func cancelValidation() {
        checking?.cancel()
        checking = nil
        verify.isEnabled = true
        apiKey.isEnabled = true
    }
    private func refreshCloudCatalog() {
        guard preferences.cloudSelected, checking == nil else { return }
        loadCatalog(key: nil, saveKey: false)
    }
    private func validateKey() {
        // Ręczne sprawdzenie ma pierwszeństwo przed odświeżeniem podczas otwierania karty.
        guard verify.isEnabled else { return }
        cancelValidation()
        apiKey.resignFirstResponder()
        let input = (apiKey.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let key: String
        do { key = input.isEmpty ? try ElevenKey.read() ?? "" : input }
        catch { report(ElevenNetwork.message(error)); return }
        guard !key.isEmpty else { report("Wpisz klucz API Eleven Labs."); return }
        loadCatalog(key: key, saveKey: true)
    }
    private func loadCatalog(key suppliedKey: String?, saveKey: Bool) {
        if saveKey {
            apiKey.isEnabled = false
            verify.isEnabled = false
            report("Sprawdzam klucz i pobieram głosy…")
        }
        checking = Task { [weak self] in
            do {
                let key: String?
                if let suppliedKey { key = suppliedKey }
                else { key = try await Task.detached { try ElevenKey.read() }.value }
                guard !Task.isCancelled else { return }
                guard let key else { self?.cancelValidation(); return }
                let catalog = try await ElevenNetwork.shared.voices(key: key)
                guard let self, !Task.isCancelled else { return }
                let changed = self.catalog != catalog
                let previous = preferences.cloudVoice
                if saveKey { try ElevenKey.save(key) }
                self.catalog = catalog
                preferences.cloudVoices = catalog
                if !catalog.contains(where: { $0.voice_id == previous }) {
                    preferences.cloudVoice = catalog.first?.voice_id
                }
                if saveKey { apiKey.text = nil }
                cancelValidation()
                forget.isHidden = false
                if changed || previous != preferences.cloudVoice || saveKey {
                    updateEngineOptions()
                    publishLayout()
                }
                let summary = catalog.isEmpty ? "Na koncie Eleven Labs nie ma dostępnych głosów." :
                    "Liczba dostępnych głosów: \(catalog.count)."
                if saveKey { report("Klucz zapisany. " + summary) }
                else if catalog.isEmpty { report(summary) }
            } catch {
                guard let self, !Task.isCancelled else { return }
                cancelValidation()
                report(ElevenNetwork.message(error))
            }
        }
    }
    private func forgetKey() {
        cancelValidation()
        do {
            try ElevenKey.remove()
            SpeechReader.shared.leave()
            apiKey.text = nil
            preferences.cloudVoices = []
            preferences.cloudVoice = nil
            catalog = []
            forget.isHidden = true
            updateEngineOptions()
            publishLayout()
            report("Usunięto klucz i listę głosów z iPhone’a.")
        } catch { report(ElevenNetwork.message(error)) }
    }
    @objc private func updateSample() {
        if visible, let error = SpeechReader.shared.takeCloudError() { notice.text = error }
        let cloud = preferences.cloudSelected
        let selected = preferences.cloudVoice
        sample.isEnabled = !cloud || selected != nil
        if cloud {
            if let chosen = catalog.first(where: { $0.voice_id == selected }), SpeechReader.shared.state == .idle {
                sample.configuration?.title = "Odsłuchaj próbkę: \(chosen.name)"
                return
            }
        }
        sample.configuration?.title = SpeechReader.shared.state == .idle ? "Odsłuchaj próbkę" : "Zatrzymaj próbkę"
    }
    private func toggleSample() {
        let player = SpeechReader.shared
        if player.state != .idle { player.stop(); return }
        do { if let message = try player.start(preferences.cloudSelected ? Self.cloudSampleText : Self.sampleText) { notice.text = message } }
        catch {
            notice.text = error.localizedDescription
            UIAccessibility.post(notification: .announcement, argument: notice.text)
        }
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refresh() }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshCloudCatalog()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelValidation()
        apiKey.text = nil
        if SpeechReader.shared.isSample { SpeechReader.shared.leave() }
    }
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
        paragraph("25 grudnia czytania Mszy o świcie i Mszy w dzień, jeśli nie ma ich w głównym źródle, pochodzą z serwisu liturgia.wiara.pl (lekcjonarz z 2015 roku).")
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
