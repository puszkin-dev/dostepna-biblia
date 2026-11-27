import UIKit

/// Jeden gest regulacji ma zmieniać dokładnie jedną pozycję, nie dziesięć procent zakresu.
final class DateSlider: UISlider {
    var format: (Int) -> String = { String($0) }
    override var accessibilityValue: String? {
        get { format(Int(value.rounded())) }
        set { super.accessibilityValue = newValue }
    }
    override func accessibilityIncrement() { move(1) }
    override func accessibilityDecrement() { move(-1) }

    private func move(_ step: Int) {
        value = min(maximumValue, max(minimumValue, value.rounded() + Float(step)))
        sendActions(for: .valueChanged)
    }
}

final class LiturgyScreen: FormScreen {
    private var date = ReadingDate()
    private var part = Part.all
    private let month = DateSlider(), day = DateSlider(), year = DateSlider()
    private let monthLabel = UILabel(), dayLabel = UILabel(), yearLabel = UILabel()
    private var partButton = UIButton()
    private var reopen = UIButton()

    override func configure() {
        month.format = { ReadingDate.months[$0 - 1] }
        addSlider(month, monthLabel, "Wybierz miesiąc", 1...12) { [weak self] in self?.date.month = $0 }
        addSlider(day, dayLabel, "Wybierz dzień", 1...date.lastDay) { [weak self] in self?.date.day = $0 }
        addSlider(year, yearLabel, "Wybierz rok", 2000...max(2000, date.year + 1)) { [weak self] in self?.date.year = $0 }
        partButton = button("Część liturgii") {}
        button("Czytaj") { [weak self] in self?.load(save: false) }
        button("Zapisz do TXT") { [weak self] in self?.load(save: true) }
        reopen = button("Otwórz pobrany tekst") { [weak self] in self?.openReading() }
    }

    private func addSlider(_ slider: DateSlider, _ label: UILabel, _ name: String, _ range: ClosedRange<Int>,
                           changed: @escaping (Int) -> Void) {
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        fields.addArrangedSubview(label)
        slider.accessibilityLabel = name
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.addAction(UIAction { [weak self, weak slider] _ in
            guard let self, let slider else { return }
            changed(Int(slider.value.rounded()))
            date.clampDay()
            clearResult()
            refresh()
        }, for: .valueChanged)
        addControl(slider)
    }

    override func refresh() {
        day.maximumValue = Float(date.lastDay)
        for (slider, label, value) in [(month, monthLabel, date.month), (day, dayLabel, date.day), (year, yearLabel, date.year)] {
            slider.value = Float(value)
            label.text = (slider.accessibilityLabel ?? "") + ": " + slider.format(value)
        }
        menu(partButton, label: "Część liturgii", names: Part.allCases.map(\.rawValue),
             index: Part.allCases.firstIndex(of: part) ?? 0) { [weak self] i in
            self?.part = Part.allCases[i]
            self?.clearResult()
            self?.refresh()
        }
        reopen.isHidden = reading == nil
    }

    private func load(save: Bool) {
        if save, let reading { export(reading); return }
        perform("Pobieranie czytań…") { [self] in
            let value = try await service.liturgy(date, part)
            display(value, save: save)
        }
    }
}
