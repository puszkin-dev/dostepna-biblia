import UIKit
import UniformTypeIdentifiers

/// Wspólne zachowanie kart: pobieranie, ogłaszanie stanu i zapis przez systemową aplikację Pliki.
class FormScreen: UIViewController, UIDocumentPickerDelegate {
    let service = BibleService()
    let fields = UIStackView()
    let choices = UIStackView()
    let status = UILabel()
    private let activity = UIActivityIndicatorView(style: .medium)
    private var controls: [UIControl] = []
    private var busy = false
    private var temporaryDirectory: URL?
    private(set) var reading: Reading?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BookStyle.paper
        view.tintColor = BookStyle.accent
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        fields.translatesAutoresizingMaskIntoConstraints = false
        fields.axis = .vertical
        fields.spacing = 12
        view.addSubview(scroll)
        scroll.addSubview(fields)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: 0),
            fields.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            fields.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            fields.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18),
            fields.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            fields.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        status.font = .preferredFont(forTextStyle: .body)
        status.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 0
        let heading = UILabel()
        heading.font = BookStyle.serif(size: 35, style: .largeTitle, traits: traitCollection, heading: true)
        heading.textColor = BookStyle.ink
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.text = title
        heading.accessibilityTraits.insert(.header)
        let header = UIStackView(arrangedSubviews: [heading])
        header.alignment = .center
        header.spacing = 8
        if !(self is ReadingSettings || self is SettingsScreen || self is AboutScreen) {
            var icon = UIButton.Configuration.gray()
            icon.image = UIImage(systemName: "textformat.size")
            icon.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)
            icon.contentInsets = .zero
            icon.cornerStyle = .capsule
            icon.baseForegroundColor = BookStyle.accent
            let settings = UIButton(configuration: icon, primaryAction: UIAction { [weak self] _ in self?.openSettings() })
            settings.accessibilityLabel = "Ustawienia czytania"
            settings.widthAnchor.constraint(equalToConstant: 48).isActive = true
            settings.heightAnchor.constraint(equalToConstant: 48).isActive = true
            header.addArrangedSubview(settings)
        }
        fields.addArrangedSubview(header)
        fields.setCustomSpacing(20, after: header)
        choices.axis = .vertical
        choices.spacing = 6
        choices.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        choices.isLayoutMarginsRelativeArrangement = true
        choices.backgroundColor = BookStyle.surface
        choices.layer.cornerRadius = 18
        choices.layer.cornerCurve = .continuous
        fields.addArrangedSubview(choices)
        status.textColor = BookStyle.ink
        configure()
        activity.hidesWhenStopped = true
        activity.isAccessibilityElement = false
        let feedback = UIStackView(arrangedSubviews: [activity, status])
        feedback.spacing = 10
        feedback.alignment = .center
        fields.addArrangedSubview(feedback)
        refresh()
    }

    func configure() {}
    func refresh() {}
    func heading(_ text: String, in stack: UIStackView) {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = BookStyle.ink
        label.accessibilityTraits.insert(.header)
        stack.addArrangedSubview(label)
    }

    @objc func openSettings() {
        let settings = ReadingSettings()
        settings.title = "Ustawienia czytania"
        navigationController?.pushViewController(settings, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(!(self is ReadingSettings || self is AboutScreen), animated: animated)
    }

    func addControl(_ control: UIControl, to stack: UIStackView? = nil) {
        controls.append(control)
        (stack ?? fields).addArrangedSubview(control)
        let minimumHeight = control.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        // Ukryty element stosu musi móc zwinąć się do zera.
        minimumHeight.priority = UILayoutPriority(999)
        minimumHeight.isActive = true
    }

    @discardableResult
    func button(_ title: String, in stack: UIStackView? = nil, action: @escaping () -> Void) -> UIButton {
        let primary = ["Czytaj", "Losuj cytat", "Szukaj"].contains(title)
        var appearance = primary ? UIButton.Configuration.filled() : UIButton.Configuration.tinted()
        appearance.baseBackgroundColor = BookStyle.accent
        appearance.baseForegroundColor = primary ? BookStyle.onAccent : BookStyle.accent
        appearance.titleLineBreakMode = .byWordWrapping
        let symbols = ["Czytaj": "book", "Losuj cytat": "quote.bubble", "Szukaj": "magnifyingglass",
                       "Zapisz do TXT": "square.and.arrow.down"]
        if let symbol = symbols[title] {
            appearance.image = UIImage(systemName: symbol)
            appearance.imagePadding = 8
        }
        appearance.title = title
        appearance.cornerStyle = .medium
        let button = UIButton(configuration: appearance, primaryAction: UIAction { _ in action() })
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        addControl(button, to: stack)
        return button
    }

    func addChoice(_ slider: ChoiceSlider, select: @escaping (Int) -> Void) {
        choices.addArrangedSubview(slider.caption)
        addControl(slider, to: choices)
        slider.onSelect = select
    }

    var visible: Bool {
        isViewLoaded && view.window != nil && navigationController?.topViewController === self
    }

    func perform(_ message: String, operation: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
        activity.startAnimating()
        controls.forEach { $0.isEnabled = false }
        status.text = message
        if visible { UIAccessibility.post(notification: .announcement, argument: message) }
        Task {
            do { try await operation() }
            catch {
                let message = (error as? ReaderError)?.message ?? "Nie udało się pobrać tekstu. Sprawdź połączenie z internetem i spróbuj ponownie."
                status.text = message
                if visible {
                    let alert = UIAlertController(title: "dostępna biblia", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
            busy = false
            activity.stopAnimating()
            controls.forEach { $0.isEnabled = true }
            refresh()
        }
    }

    func clearResult() {
        reading = nil
        status.text = nil
    }

    func display(_ value: Reading, save: Bool = false) {
        reading = value
        status.text = value.name
        guard visible else { return }
        if save { export(value) } else { openReading() }
    }

    func openReading() {
        guard let reading else { return }
        let reader = TextScreen(reading: reading)
        reader.onSave = { [weak self] in self?.export(reading) }
        navigationController?.pushViewController(reader, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    func export(_ value: Reading) {
        let presenter = navigationController?.topViewController ?? self
        guard presenter.viewIfLoaded?.window != nil, presenter.presentedViewController == nil else { return }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = try value.writeTXT(in: directory)
            temporaryDirectory = directory
            let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
            picker.delegate = self
            presenter.present(picker, animated: true)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            let alert = UIAlertController(title: "Błąd zapisu", message: "Nie udało się przygotować pliku TXT.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            presenter.present(alert, animated: true)
        }
    }

    private func endExport() {
        if let temporaryDirectory { try? FileManager.default.removeItem(at: temporaryDirectory) }
        temporaryDirectory = nil
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { endExport() }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        endExport()
        if let url = urls.first {
            let message = "Zapisano \(url.lastPathComponent)"
            status.text = message
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

final class TextScreen: UIViewController {
    private let reading: Reading
    private let textView = UITextView()
    var resumeOnOpen = false
    private var resumable = false
    private var firstOpen = true
    private var destination: Reading.Verse?
    private let playback = UIStackView()
    private let play = UIButton(type: .system)
    private let rewind = UIButton(type: .system)
    private let halt = UIButton(type: .system)
    private var transportWidths: [NSLayoutConstraint] = []
    var onSave: (() -> Void)?

    init(reading: Reading) {
        self.reading = reading
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tekst"
        let saveItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(save))
        saveItem.accessibilityLabel = "Zapisz do TXT"
        var items = [saveItem, BookStyle.settingsIcon(target: self, action: #selector(openSettings))]
        if !reading.verses.isEmpty {
            let verses = UIBarButtonItem(image: UIImage(systemName: "list.number"), style: .plain, target: self, action: #selector(openVerses))
            verses.accessibilityLabel = "Przejdź do wersetu"
            items.append(verses)
        }
        navigationItem.rightBarButtonItems = items
        view.backgroundColor = BookStyle.paper
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = BookStyle.paper
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = UIEdgeInsets(top: 22, left: 18, bottom: 28, right: 18)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self,
                                UITraitAccessibilityContrast.self, UITraitUserInterfaceStyle.self]) {
            (screen: TextScreen, _: UITraitCollection) in screen.typeset()
        }
        textView.accessibilityIdentifier = "tekstWyniku"
        textView.selectedRange = NSRange(location: 0, length: 0)
        view.addSubview(textView)
        configurePlayback()
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: playback.bottomAnchor, constant: 4),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configurePlayback() {
        playback.spacing = 8
        playback.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playback)
        for (control, label, symbol, action) in [
            (play, "Czytaj na głos", "play.fill", #selector(toggleSpeech)),
            (rewind, "Czytaj od początku", "arrow.counterclockwise", #selector(startSpeech)),
            (halt, "Zatrzymaj czytanie", "stop.fill", #selector(stopSpeech))
        ] {
            var config = UIButton.Configuration.tinted()
            config.image = UIImage(systemName: symbol)
            config.imagePadding = 8
            config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)
            config.titleLineBreakMode = .byWordWrapping
            control.configuration = config
            control.accessibilityLabel = label
            control.showsLargeContentViewer = true
            control.largeContentTitle = label
            control.largeContentImage = config.image
            control.addTarget(self, action: action, for: .touchUpInside)
            playback.addArrangedSubview(control)
            control.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            if control !== play { transportWidths.append(control.widthAnchor.constraint(equalToConstant: 46)) }
        }
        NSLayoutConstraint.activate([
            playback.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            playback.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            playback.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4)
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayback), name: SpeechReader.changed, object: nil)
        playback.addInteraction(UILargeContentViewerInteraction())
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (screen: TextScreen, _: UITraitCollection) in screen.updatePlayback()
        }
        updatePlayback()
    }
    @objc private func updatePlayback() {
        let state = SpeechReader.shared.state
        let label: String
        switch state {
        case .idle:
            if SpeechPreferences().cloudSelected, let (book, _) = ElevenBookmark.load(), book.title == reading.name {
                resumable = book.parts == ElevenText.chunks(ElevenText.clean(reading.text)) || book.parts.joined(separator: "\n\n") == reading.text
            } else { resumable = false }
            label = resumable ? "Wznów czytanie" : "Czytaj na głos"
        case .preparing: label = "Przygotowywanie mowy…"
        case .paused: label = "Wznów czytanie"
        case .speaking: label = "Wstrzymaj czytanie"
        }
        let showTransport = state != .idle || resumable
        let largeControls = traitCollection.preferredContentSizeCategory.isAccessibilityCategory && showTransport
        transportWidths.forEach { $0.isActive = !largeControls && showTransport }
        playback.distribution = largeControls ? .fillEqually : .fill
        play.configuration?.title = largeControls ? nil : label
        play.configuration?.image = UIImage(systemName: state == .speaking ? "pause.fill" : "play.fill")
        play.accessibilityLabel = label
        play.largeContentTitle = label
        play.largeContentImage = play.configuration?.image
        play.isEnabled = state != .preparing
        halt.isHidden = !showTransport
        rewind.isHidden = !showTransport
        if state == .idle, viewIfLoaded?.window != nil, navigationController?.topViewController === self, presentedViewController == nil, let message = SpeechReader.shared.takeCloudError() {
            let alert = UIAlertController(title: "Czytanie na głos", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: !UIAccessibility.isReduceMotionEnabled)
        }
    }
    @objc private func toggleSpeech() {
        switch SpeechReader.shared.state {
        case .idle: beginSpeech(fromBeginning: false)
        case .preparing: break
        case .speaking: SpeechReader.shared.pause()
        case .paused: SpeechReader.shared.resume()
        }
    }
    @objc private func startSpeech() { beginSpeech(fromBeginning: true) }
    private func beginSpeech(fromBeginning: Bool) {
        do {
            if let message = try SpeechReader.shared.start(reading.text, title: reading.name, fromBeginning: fromBeginning) {
                let alert = UIAlertController(title: "Zmieniono głos", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        } catch {
            let alert = UIAlertController(title: "Czytanie na głos", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    @objc private func stopSpeech() {
        if SpeechReader.shared.state == .idle && resumable {
            do { try ElevenBookmark.clear(); updatePlayback() } catch {
                let alert = UIAlertController(title: "Czytanie na głos", message: "Nie udało się usunąć zapisanego miejsca.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        } else { SpeechReader.shared.stop() }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SpeechReader.shared.leave()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if resumeOnOpen {
            resumeOnOpen = false
            beginSpeech(fromBeginning: false)
        }
        if let destination {
            self.destination = nil
            textView.selectedRange = NSRange(location: destination.offset, length: 0)
            textView.scrollRangeToVisible(textView.selectedRange)
            UIAccessibility.post(notification: .screenChanged, argument: textView)
            UIAccessibility.post(notification: .announcement, argument: "Werset \(destination.number). " + reading.excerpt(destination))
        } else if firstOpen {
            firstOpen = false
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIAccessibility.post(notification: .screenChanged, argument: play)
        }
    }

    @objc private func save() { onSave?() }
    @objc private func openSettings() {
        let settings = ReadingSettings()
        settings.title = "Ustawienia czytania"
        navigationController?.pushViewController(settings, animated: !UIAccessibility.isReduceMotionEnabled)
    }
    @objc private func openVerses() {
        let list = VerseList(reading: reading)
        list.select = { [weak self] verse in self?.destination = verse }
        navigationController?.pushViewController(list, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    private func typeset() {
        let selection = textView.selectedRange
        let font = ReadingSize().font(traitCollection)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = font.pointSize * 0.16
        paragraph.alignment = .natural
        let output = NSMutableAttributedString(string: reading.text, attributes: [
            .font: font, .foregroundColor: BookStyle.ink, .paragraphStyle: paragraph])
        if let end = reading.text.firstIndex(of: "\n") {
            let range = NSRange(reading.text.startIndex..<end, in: reading.text)
            let size = ReadingSize.points[ReadingSize().index] + 5
            output.addAttribute(.font, value: BookStyle.serif(size: size, style: .title2, traits: traitCollection, heading: true), range: range)
        }
        for verse in reading.verses {
            output.addAttribute(.foregroundColor, value: BookStyle.accent,
                                range: NSRange(location: verse.offset, length: String(verse.number).utf16.count))
        }
        textView.attributedText = output
        if NSMaxRange(selection) <= output.length { textView.selectedRange = selection }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        typeset()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
