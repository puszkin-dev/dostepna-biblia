import UIKit

final class BibleScreen: FormScreen {
    private let scopes = ["Cała Biblia", "Stary Testament", "Nowy Testament"]
    private var scope = 0
    private var books = Book.all
    private var selectedBook = 0
    private var chapters: [Int] = []
    private var selectedChapter = 0
    private var cache: [Book: [Int]] = [:]
    private var scopeButton = UIButton(), bookButton = UIButton(), chapterButton = UIButton()
    private var read = UIButton(), save = UIButton(), retry = UIButton()

    override func configure() {
        scopeButton = button("Co chcesz czytać") {}
        bookButton = button("Wybierz księgę") {}
        chapterButton = button("Wybierz rozdział") {}
        read = button("Czytaj") { [weak self] in self?.load(save: false) }
        save = button("Zapisz do TXT") { [weak self] in self?.load(save: true) }
        retry = button("Pobierz listę rozdziałów ponownie") { [weak self] in self?.loadChapters() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if chapters.isEmpty { loadChapters() }
    }
    override func refresh() {
        menu(scopeButton, label: "Co chcesz czytać", names: scopes, index: scope) { [weak self] i in
            guard let self else { return }
            scope = i
            books = Book.all.filter { i == 0 || $0.newTestament == (i == 2) }
            selectedBook = 0
            loadChapters()
        }
        menu(bookButton, label: "Wybierz księgę", names: books.map(\.name), index: selectedBook) { [weak self] i in
            self?.selectedBook = i
            self?.loadChapters()
        }
        menu(chapterButton, label: "Wybierz rozdział", names: chapters.map { $0 == 0 ? "0 — Wstęp" : String($0) },
             index: selectedChapter) { [weak self] i in
            self?.selectedChapter = i
            self?.clearResult()
            self?.refresh()
        }
        for control in [chapterButton, read, save] { control.isEnabled = !chapters.isEmpty }
        retry.isHidden = !chapters.isEmpty
    }

    private func loadChapters() {
        let book = books[selectedBook]
        clearResult()
        selectedChapter = 0
        chapters = cache[book] ?? []
        refresh()
        guard chapters.isEmpty else { return }
        perform("Pobieranie listy rozdziałów…") { [self] in
            let numbers = try await service.chapters(book)
            cache[book] = numbers
            chapters = numbers
            status.text = "Wybierz księgę i rozdział."
        }
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
    private var category = UIButton(), draw = UIButton(), save = UIButton(), back = UIButton()
    override func configure() {
        category = button("Kategoria cytatu") {}
        draw = button("Losuj cytat") { [weak self] in self?.load() }
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
        menu(category, label: "Kategoria cytatu", names: BibleService.categories, index: index) { [weak self] i in
            self?.index = i
            self?.refresh()
        }
        category.isHidden = reading != nil
        draw.configuration?.title = reading == nil ? "Losuj cytat" : "Losuj ponownie"
        back.isHidden = reading == nil
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
    private var phrase = ""
    private var number = 0
    private var page: SearchPage?

    override func configure() {
        query.placeholder = "Słowa kluczowe"
        query.accessibilityLabel = "Słowa kluczowe"
        query.font = .preferredFont(forTextStyle: .body)
        query.adjustsFontForContentSizeCategory = true
        query.borderStyle = .roundedRect
        query.returnKeyType = .search
        query.autocorrectionType = .no
        query.delegate = self
        addControl(query)
        button("Szukaj") { [weak self] in self?.firstPage() }
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
