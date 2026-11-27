import UIKit

enum BookStyle {
    static let paper = UIColor { traits in
        if traits.accessibilityContrast == .high { return traits.userInterfaceStyle == .dark ? .black : .white }
        return traits.userInterfaceStyle == .dark ? rgb(0x151D22) : rgb(0xF8F5ED)
    }
    static let surface = UIColor { $0.userInterfaceStyle == .dark ? rgb(0x212D33) : .white }
    static let ink = UIColor { traits in
        if traits.accessibilityContrast == .high { return traits.userInterfaceStyle == .dark ? .white : .black }
        return traits.userInterfaceStyle == .dark ? rgb(0xF5EEDC) : rgb(0x202E32)
    }
    static let accent = UIColor { $0.userInterfaceStyle == .dark ? rgb(0xEBC88B) : rgb(0x264F52) }
    static let onAccent = UIColor { $0.userInterfaceStyle == .dark ? rgb(0x182427) : .white }
    static let track = UIColor { $0.userInterfaceStyle == .dark ? rgb(0x8C9C9D) : rgb(0x748080) }
    private static func rgb(_ number: Int) -> UIColor {
        UIColor(red: CGFloat(number >> 16) / 255, green: CGFloat(number >> 8 & 255) / 255,
                blue: CGFloat(number & 255) / 255, alpha: 1)
    }

    static func serif(size: CGFloat, style: UIFont.TextStyle, traits: UITraitCollection, heading: Bool = false) -> UIFont {
        let weight: UIFont.Weight = heading || traits.legibilityWeight == .bold || UIAccessibility.isBoldTextEnabled ? .bold : .regular
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        return UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: size), compatibleWith: traits)
    }

    static func settingsIcon(target: Any, action: Selector) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: UIImage(systemName: "textformat.size"), style: .plain, target: target, action: action)
        item.accessibilityLabel = "Ustawienia czytania"
        return item
    }
}

struct ReadingSize {
    static let points: [CGFloat] = [16, 18, 20, 23, 26]
    static let labels = ["Mniejszy", "Standardowy", "Większy", "Duży", "Bardzo duży"]
    static let standard = 1
    static let key = "rozmiarTekstuCzytan"
    let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var index: Int {
        get {
            guard let n = defaults.object(forKey: Self.key) as? Int, Self.points.indices.contains(n) else { return Self.standard }
            return n
        }
        nonmutating set {
            guard Self.points.indices.contains(newValue) else { return }
            defaults.set(newValue, forKey: Self.key)
        }
    }
    func font(_ traits: UITraitCollection) -> UIFont {
        BookStyle.serif(size: Self.points[index], style: .body, traits: traits)
    }
}

final class ReadingSettings: FormScreen {
    private let size = ReadingSize()
    private let slider = ChoiceSlider("Wielkość tekstu Biblii")
    private let sample = UILabel()
    override func configure() {
        navigationItem.title = ""
        addChoice(slider) { [weak self] index in
            self?.size.index = index
            self?.refresh()
        }
        sample.text = "Na początku było Słowo."
        sample.numberOfLines = 0
        sample.accessibilityLabel = "Podgląd: Na początku było Słowo."
        sample.textColor = BookStyle.ink
        choices.addArrangedSubview(sample)
        button("Przywróć domyślny rozmiar") { [weak self] in
            self?.size.index = ReadingSize.standard
            self?.refresh()
            UIAccessibility.post(notification: .announcement, argument: "Przywrócono rozmiar standardowy.")
        }
        status.text = "Rozmiar tekstu uwzględnia także ustawienie Większy tekst w iPhonie."
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self]) {
            (screen: ReadingSettings, _: UITraitCollection) in screen.refresh()
        }
    }
    override func refresh() {
        slider.show(ReadingSize.labels, index: size.index)
        sample.font = size.font(traitCollection)
    }
}
