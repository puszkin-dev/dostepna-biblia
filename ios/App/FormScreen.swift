import UIKit
import UniformTypeIdentifiers

/// Wspólne zachowanie kart: pobieranie, ogłaszanie stanu i zapis przez systemową aplikację Pliki.
class FormScreen: UIViewController, UIDocumentPickerDelegate {
    let service = BibleService()
    let fields = UIStackView()
    let status = UILabel()
    private var controls: [UIControl] = []
    private var busy = false
    private var temporaryDirectory: URL?
    private(set) var reading: Reading?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
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
            fields.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            fields.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            fields.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            fields.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            fields.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
        status.font = .preferredFont(forTextStyle: .body)
        status.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 0
        configure()
        fields.addArrangedSubview(status)
        refresh()
    }

    func configure() {}
    func refresh() {}

    func addControl(_ control: UIControl) {
        controls.append(control)
        fields.addArrangedSubview(control)
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    }

    @discardableResult
    func button(_ title: String, action: @escaping () -> Void) -> UIButton {
        var appearance = UIButton.Configuration.tinted()
        appearance.title = title
        appearance.cornerStyle = .medium
        let button = UIButton(configuration: appearance, primaryAction: UIAction { _ in action() })
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        addControl(button)
        return button
    }

    func menu(_ button: UIButton, label: String, names: [String], index: Int, select: @escaping (Int) -> Void) {
        let current = names.indices.contains(index) ? names[index] : "Brak"
        button.configuration?.title = "\(label): \(current)"
        button.accessibilityLabel = label
        button.accessibilityValue = current
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(children: names.enumerated().map { i, name in
            UIAction(title: name, state: i == index ? .on : .off) { _ in select(i) }
        })
    }

    var visible: Bool {
        isViewLoaded && view.window != nil && navigationController?.topViewController === self
    }

    func perform(_ message: String, operation: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
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
        navigationController?.pushViewController(reader, animated: true)
    }

    func export(_ value: Reading) {
        let presenter = navigationController?.topViewController ?? self
        guard presenter.viewIfLoaded?.window != nil, presenter.presentedViewController == nil else { return }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let name = value.name.replacingOccurrences(of: "/", with: "-") + ".txt"
        let url = directory.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data(value.text.utf8).write(to: url, options: .atomic)
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
    var onSave: (() -> Void)?

    init(reading: Reading) {
        self.reading = reading
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = reading.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Zapisz do TXT", style: .plain, target: self, action: #selector(save))
        view.backgroundColor = .systemBackground
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 20, right: 12)
        textView.text = reading.text
        textView.accessibilityIdentifier = "tekstWyniku"
        textView.selectedRange = NSRange(location: 0, length: 0)
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        UIAccessibility.post(notification: .screenChanged, argument: textView)
    }

    @objc private func save() { onSave?() }
}
