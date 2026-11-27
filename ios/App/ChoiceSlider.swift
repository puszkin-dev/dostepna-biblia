import UIKit

/// Dyskretny suwak systemowy. Gest VoiceOver zmienia wybór o jedną pozycję.
final class ChoiceSlider: UISlider {
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

    func show(_ names: [String], index: Int) {
        self.names = names
        minimumValue = 0
        maximumValue = Float(max(1, names.count - 1))
        value = Float(min(max(0, index), max(0, names.count - 1)))
        caption.text = name + ": " + (accessibilityValue ?? "Brak")
        isEnabled = names.count > 1
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
