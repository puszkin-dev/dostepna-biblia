import UIKit

/// Dyskretny suwak systemowy. Gest VoiceOver zmienia wybór o jedną pozycję.
class ChoiceSlider: UISlider {
    let caption = UILabel()
    private var names: [String] = []
    private let name: String
    var onSelect: ((Int) -> Void)?

    init(_ name: String) {
        self.name = name
        super.init(frame: .zero)
        accessibilityLabel = name
        minimumTrackTintColor = BookStyle.accent
        maximumTrackTintColor = BookStyle.track
        isContinuous = false
        caption.font = .preferredFont(forTextStyle: .body)
        caption.adjustsFontForContentSizeCategory = true
        caption.numberOfLines = 0
        caption.textColor = BookStyle.ink
        caption.isAccessibilityElement = false
        caption.accessibilityElementsHidden = true
        addTarget(self, action: #selector(changeByTouch), for: .valueChanged)
    }
    required init?(coder: NSCoder) { nil }

    func show(_ names: [String], index: Int, informational: Bool = false) {
        self.names = names
        minimumValue = 0
        maximumValue = Float(max(1, names.count - 1))
        value = Float(min(max(0, index), max(0, names.count - 1)))
        caption.text = name + ": " + (accessibilityValue ?? "Brak")
        isEnabled = names.count > 1 || informational
    }
    override var accessibilityValue: String? {
        get {
            let index = Int(value.rounded())
            return names.indices.contains(index) ? names[index] : "Brak"
        }
        set { super.accessibilityValue = newValue }
    }
    override func accessibilityIncrement() { select(Int(value.rounded()) + 1) }
    override func accessibilityDecrement() { select(Int(value.rounded()) - 1) }
    @objc private func changeByTouch() { select(Int(value.rounded())) }
    private func select(_ index: Int) {
        guard isEnabled, names.indices.contains(index) else { return }
        value = Float(index)
        caption.text = name + ": " + names[index]
        onSelect?(index)
    }
}

/// Jedno stałe miejsce fokusu: lista głosów albo informacja o jedynym głosie.
final class VoiceChoiceSlider: ChoiceSlider {
    private let onlyLabel = UILabel()
    private var onlyValue: String?
    private let keyButton = UIButton(type: .system)
    private var openKey: (() -> Void)?

    init() {
        super.init("Głos")
        onlyLabel.font = .preferredFont(forTextStyle: .body)
        onlyLabel.adjustsFontForContentSizeCategory = true
        onlyLabel.numberOfLines = 0
        onlyLabel.textColor = BookStyle.ink
        onlyLabel.isAccessibilityElement = false
        onlyLabel.isUserInteractionEnabled = false
        onlyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(onlyLabel)
        var config = UIButton.Configuration.tinted()
        config.titleLineBreakMode = .byWordWrapping
        config.baseForegroundColor = BookStyle.accent
        keyButton.configuration = config
        keyButton.titleLabel?.numberOfLines = 0
        keyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        keyButton.isAccessibilityElement = false
        keyButton.isHidden = true
        keyButton.translatesAutoresizingMaskIntoConstraints = false
        keyButton.addAction(UIAction { [weak self] _ in self?.openKey?() }, for: .touchUpInside)
        addSubview(keyButton)
        NSLayoutConstraint.activate([
            keyButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyButton.topAnchor.constraint(equalTo: topAnchor),
            keyButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            onlyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            onlyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            onlyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualTo: onlyLabel.heightAnchor)
        ])
    }
    required init?(coder: NSCoder) { nil }

    func present(_ names: [String], index: Int) {
        if names.count == 1 {
            inform("\(names[0]), jedyny głos tego silnika")
            return
        }
        openKey = nil
        keyButton.configuration?.title = nil
        keyButton.isHidden = true
        accessibilityLabel = "Głos"
        onlyValue = nil
        onlyLabel.text = nil
        onlyLabel.isHidden = true
        caption.isHidden = false
        show(names, index: index)
        setNeedsLayout()
    }

    func inform(_ message: String) {
        openKey = nil
        keyButton.configuration?.title = nil
        keyButton.isHidden = true
        accessibilityLabel = "Głos"
        onlyValue = message
        onlyLabel.text = "Głos: " + message
        onlyLabel.isHidden = false
        caption.isHidden = true
        show([message], index: 0, informational: true)
        setNeedsLayout()
    }

    func offer(_ title: String, action: @escaping () -> Void) {
        inform(title)
        openKey = action
        onlyLabel.isHidden = true
        onlyLabel.text = nil
        keyButton.configuration?.title = title
        keyButton.isHidden = false
        accessibilityLabel = title
    }

    override func accessibilityActivate() -> Bool {
        guard let openKey else { return super.accessibilityActivate() }
        openKey()
        return true
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            if openKey != nil { return .button }
            return onlyValue == nil ? super.accessibilityTraits : .staticText
        }
        set { super.accessibilityTraits = newValue }
    }
    override var accessibilityValue: String? {
        get { openKey == nil ? onlyValue ?? super.accessibilityValue : nil }
        set { super.accessibilityValue = newValue }
    }
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        onlyValue == nil ? super.trackRect(forBounds: bounds) : .zero
    }
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        onlyValue == nil ? super.thumbRect(forBounds: bounds, trackRect: rect, value: value) : .zero
    }
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        onlyValue == nil && super.beginTracking(touch, with: event)
    }
}
