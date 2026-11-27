import UIKit

final class BibleScreen: FormScreen {
    private let scopes = ["Cała Biblia", "Stary Testament", "Nowy Testament"]
    private var scope = 0
    private var books = Book.all
    private var selectedBook = 0
    private var chapters: [Int] = []
    private var selectedChapter = 0
    private var cache: [Book: [Int]] = [:]
    private let scopeSlider = ChoiceSlider("Co chcesz czytać")
    private let bookSlider = ChoiceSlider("Wybierz księgę")
    private let chapterSlider = ChoiceSlider("Wybierz rozdział")
    private var chapterTask: Task<Void, Never>?
    private var read = UIButton(), save = UIButton(), retry = UIButton()

    override func configure() {
        addChoice(scopeSlider) { [weak self] i in
            guard let self else { return }
            scope = i
            books = Book.all.filter { i == 0 || $0.newTestament == (i == 2) }
            selectedBook = 0
            loadChapters()
        }
        addChoice(bookSlider) { [weak self] i in
            self?.selectedBook = i
            self?.loadChapters()
        }
        addChoice(chapterSlider) { [weak self] i in
            self?.selectedChapter = i
            self?.clearResult()
            self?.refresh()
        }
        read = button("Czytaj") { [weak self] in self?.load(save: false) }
        save = button("Zapisz do TXT") { [weak self] in self?.load(save: true) }
        retry = button("Pobierz listę rozdziałów ponownie") { [weak self] in self?.loadChapters() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if chapters.isEmpty && chapterTask == nil { loadChapters() }
    }
    override func refresh() {
        scopeSlider.show(scopes, index: scope)
        bookSlider.show(books.map(\.name), index: selectedBook)
        chapterSlider.show(chapters.map { $0 == 0 ? "0 — Wstęp" : String($0) }, index: selectedChapter)
        read.isEnabled = !chapters.isEmpty
        save.isEnabled = !chapters.isEmpty
        retry.isHidden = !chapters.isEmpty || chapterTask != nil
    }

    private func loadChapters() {
        let book = books[selectedBook]
        chapterTask?.cancel()
        chapterTask = nil
        clearResult()
        selectedChapter = 0
        chapters = cache[book] ?? []
        refresh()
        guard chapters.isEmpty else { return }
        status.text = "Pobieranie listy rozdziałów…"
        chapterTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                let numbers = try await service.chapters(book)
                try Task.checkCancellation()
                cache[book] = numbers
                chapters = numbers
                status.text = "Wybierz księgę i rozdział."
            } catch {
                guard !Task.isCancelled else { return }
                let message = (error as? ReaderError)?.message ?? "Nie udało się pobrać rozdziałów. Sprawdź połączenie."
                status.text = message
                if visible { UIAccessibility.post(notification: .announcement, argument: message) }
            }
            chapterTask = nil
            refresh()
        }
        retry.isHidden = true
    }
    private func load(save: Bool) {
        guard chapters.indices.contains(selectedChapter) else { return }
        if save, let reading { export(reading); return }
        perform("Pobieranie rozdziału…") { [self] in
            let value = try await service.chapter(books[selectedBook], chapters[selectedChapter])
            display(value, save: save)
        }
    }
}

final class QuoteScreen: FormScreen {
    private var index = 0
    private let category = ChoiceSlider("Kategoria cytatu")
    private var draw = UIButton(), save = UIButton(), back = UIButton()
    private var reopen = UIButton()
    override func configure() {
        addChoice(category) { [weak self] i in
            self?.index = i
            self?.refresh()
        }
        draw = button("Losuj cytat") { [weak self] in self?.load() }
        reopen = button("Otwórz wylosowany cytat") { [weak self] in self?.openReading() }
        save = button("Zapisz do TXT") { [weak self] in
            if let self, let reading { export(reading) }
        }
        back = button("Powrót") { [weak self] in
            guard let self else { return }
            clearResult()
            refresh()
            UIAccessibility.post(notification: .layoutChanged, argument: category)
        }
    }
    override func refresh() {
        category.show(BibleService.categories, index: index)
        category.isHidden = reading != nil
        category.caption.isHidden = category.isHidden
        draw.configuration?.title = reading == nil ? "Losuj cytat" : "Losuj ponownie"
        back.isHidden = reading == nil
        reopen.isHidden = reading == nil
        save.isHidden = reading == nil
    }
    private func load() {
        perform("Losowanie cytatu…") { [self] in
            let value = try await service.quote(BibleService.categories[index])
            display(value)
        }
    }
}

final class SearchScreen: FormScreen, UITextFieldDelegate {
    private let query = UITextField()
    private var previous = UIButton(), nextButton = UIButton(), save = UIButton()
    private var reopen = UIButton()
    private var phrase = ""
    private var number = 0
    private var page: SearchPage?

    override func configure() {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = "Słowa kluczowe"
        label.isAccessibilityElement = false
        label.accessibilityElementsHidden = true
        fields.addArrangedSubview(label)
        query.accessibilityLabel = "Słowa kluczowe"
        query.font = .preferredFont(forTextStyle: .body)
        query.adjustsFontForContentSizeCategory = true
        query.borderStyle = .roundedRect
        query.returnKeyType = .search
        query.autocorrectionType = .no
        query.delegate = self
        addControl(query)
        button("Szukaj") { [weak self] in self?.firstPage() }
        reopen = button("Otwórz wyniki") { [weak self] in self?.openReading() }
        previous = button("Poprzednia strona") { [weak self] in
            guard let self, let url = page?.previous else { return }
            load(phrase, url, number - 1)
        }
        nextButton = button("Następna strona") { [weak self] in
            guard let self, let url = page?.next else { return }
            load(phrase, url, number + 1)
        }
        save = button("Zapisz do TXT") { [weak self] in
            if let self, let reading { export(reading) }
        }
    }
    override func refresh() {
        previous.isEnabled = page?.previous != nil
        nextButton.isEnabled = page?.next != nil
        save.isEnabled = reading != nil
        reopen.isHidden = reading == nil
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { firstPage(); return false }
    private func firstPage() {
        query.resignFirstResponder()
        load((query.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines), nil, 1)
    }
    private func load(_ input: String, _ url: URL?, _ index: Int) {
        perform("Wyszukiwanie w Biblii…") { [self] in
            let results = try await service.search(input, page: url)
            page = results
            phrase = input
            number = index
            clearResult()
            guard !results.items.isEmpty else { throw ReaderError("Brak wyników dla: „\(input)”.") }
            let title = "Wyniki dla: „\(input)” — strona \(index)"
            let text = ([title] + results.items + [BibleService.source]).joined(separator: "\n\n")
            display(Reading(name: "Wyniki wyszukiwania - strona \(index)", text: text))
        }
    }
}
