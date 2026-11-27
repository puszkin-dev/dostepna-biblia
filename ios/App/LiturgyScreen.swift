import UIKit

/// Systemowe koło daty. Każda kolumna jest osobną regulacją VoiceOver.
final class CalendarWheels: UIPickerView, UIPickerViewDataSource, UIPickerViewAccessibilityDelegate {
    private(set) var date: ReadingDate
    let years: ClosedRange<Int>
    private let names = ["Wybierz miesiąc", "Wybierz dzień", "Wybierz rok"]
    var changed: (() -> Void)?

    init(today: ReadingDate = ReadingDate()) {
        date = today
        years = 2000...max(2000, today.year + 1)
        super.init(frame: .zero)
        dataSource = self
        delegate = self
        selectRow(date.month - 1, inComponent: 0, animated: false)
        selectRow(date.day - 1, inComponent: 1, animated: false)
        selectRow(date.year - years.lowerBound, inComponent: 2, animated: false)
    }
    required init?(coder: NSCoder) { nil }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { names.count }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return 12
        case 1: return date.lastDay
        default: return years.count
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return ReadingDate.months[row]
        case 1: return String(row + 1)
        default: return String(years.lowerBound + row)
        }
    }
    func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String? {
        names[component]
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        pickerView.bounds.width * [0.45, 0.18, 0.32][component]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let oldLimit = date.lastDay
        switch component {
        case 0: date.month = row + 1
        case 1: date.day = row + 1
        default: date.year = years.lowerBound + row
        }
        date.clampDay()
        if oldLimit != date.lastDay {
            reloadComponent(1)
            selectRow(date.day - 1, inComponent: 1, animated: false)
        }
        changed?()
    }

    func adjust(_ component: Int, _ row: Int) {
        selectRow(row, inComponent: component, animated: false)
        pickerView(self, didSelectRow: row, inComponent: component)
    }
}

final class LiturgyScreen: FormScreen {
    private let wheels = CalendarWheels()
    private let largeDate = ["Wybierz miesiąc", "Wybierz dzień", "Wybierz rok"].map(ChoiceSlider.init)
    private var part = Part.all
    private let partSlider = ChoiceSlider("Część liturgii")
    private var reopen = UIButton()

    override func configure() {
        wheels.changed = { [weak self] in
            self?.clearResult()
            self?.refresh()
        }
        choices.addArrangedSubview(wheels)
        for (component, slider) in largeDate.enumerated() {
            addChoice(slider) { [weak self] row in self?.wheels.adjust(component, row) }
        }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (screen: LiturgyScreen, _: UITraitCollection) in screen.refresh()
        }
        addChoice(partSlider) { [weak self] i in
            self?.part = Part.allCases[i]
            self?.clearResult()
            self?.refresh()
        }
        button("Czytaj") { [weak self] in self?.load(save: false) }
        button("Zapisz do TXT") { [weak self] in self?.load(save: true) }
        reopen = button("Otwórz pobrany tekst") { [weak self] in self?.openReading() }
    }

    override func refresh() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        wheels.isHidden = large
        for slider in largeDate {
            slider.caption.isHidden = !large
            slider.isHidden = !large
        }
        let date = wheels.date
        largeDate[0].show(ReadingDate.months, index: date.month - 1)
        largeDate[1].show((1...date.lastDay).map(String.init), index: date.day - 1)
        largeDate[2].show(wheels.years.map(String.init), index: date.year - wheels.years.lowerBound)
        partSlider.show(Part.allCases.map(\.rawValue), index: Part.allCases.firstIndex(of: part) ?? 0)
        reopen.isHidden = reading == nil
    }

    private func load(save: Bool) {
        if save, let reading { export(reading); return }
        let date = wheels.date
        wheels.isUserInteractionEnabled = false
        wheels.accessibilityElementsHidden = true
        perform("Pobieranie czytań…") { [self] in
            defer {
                wheels.isUserInteractionEnabled = true
                wheels.accessibilityElementsHidden = false
            }
            let value = try await service.liturgy(date, part)
            display(value, save: save)
        }
    }
}
