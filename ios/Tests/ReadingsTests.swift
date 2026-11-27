import XCTest
@testable import DostepnaBiblia

final class ReadingsTests: XCTestCase {
    func testPlikTXT() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let value = Reading(name: "Rozdział 1/2", text: "Miłość\n\nŹródło: TwojaBiblia.pl")
        let file = try value.writeTXT(in: directory)
        XCTAssertEqual(file.lastPathComponent, "Rozdział 1-2.txt")
        XCTAssertEqual(try Data(contentsOf: file), Data(value.text.utf8))
        XCTAssertThrowsError(try value.writeTXT(in: file))
    }

    @MainActor func testSuwakBezMenu() {
        let field = ChoiceSlider("Część liturgii")
        let parts = Part.allCases.map(\.rawValue)
        var selections: [Int] = []
        field.onSelect = { selections.append($0) }
        field.show(parts, index: 0)
        field.accessibilityDecrement()
        field.accessibilityIncrement()
        XCTAssertEqual(field.accessibilityValue, "Pierwsze czytanie")
        field.accessibilityDecrement()
        XCTAssertEqual(selections, [1, 0])
        field.show(parts, index: parts.count - 1)
        field.accessibilityIncrement()
        XCTAssertEqual(field.accessibilityValue, "Ewangelia")
        field.show([], index: 4)
        XCTAssertFalse(field.isEnabled)
        XCTAssertEqual(field.accessibilityValue, "Brak")
    }
    func testKalendarz() {
        var date = ReadingDate()
        date.year = 2024
        date.month = 2
        date.day = 31
        date.clampDay()
        XCTAssertEqual(date.iso, "2024-02-29")
        date.year = 2025
        date.clampDay()
        XCTAssertEqual(date.day, 28)
        date.month = 12
        XCTAssertEqual(date.lastDay, 31)
    }

    func testCzesci() throws {
        let text = "I CZYTANIE (Rdz)\nTreść\nPSALM\nRefren\nMSZA W CZASIE DNIA\nPSALM RESPONSORYJNY\nDrugi refren\nEWANGELIA\nTekst"
        XCTAssertEqual(try BibleService.select(text, .all), text)
        XCTAssertEqual(try BibleService.select(text, .psalm), "PSALM\nRefren\n\nPSALM RESPONSORYJNY\nDrugi refren")
        XCTAssertThrowsError(try BibleService.select(text, .second))
    }

    func testKatalog() {
        XCTAssertEqual(Book.all.count, 73)
        XCTAssertEqual(Set(Book.all.map(\.code)).count, 73)
        XCTAssertEqual(Book.all.filter(\.newTestament).count, 27)
    }

    func testRozdzialyIWstep() async throws {
        let book = try XCTUnwrap(Book.all.first { $0.code == "Jud" })
        let html = """
        <div class="chapter-selector"><a>0</a></div>
        <p data-chapter="0" class="A5-KSIEGATYTUL">Tytuł</p><p data-chapter="0">Wstęp</p>
        <p data-chapter="0" class="A5-KSIEGATYTUL">Tytuł</p><p data-chapter="0">Werset<span class="footnote-trigger"><span>szum</span></span>.</p>
        """
        let service = BibleService { _ in Data(html.utf8) }
        let numbers = try await service.chapters(book)
        XCTAssertEqual(numbers, [0, 1])
        let intro = try await service.chapter(book, 0)
        let body = try await service.chapter(book, 1)
        XCTAssertFalse(intro.text.contains("Werset"))
        XCTAssertTrue(body.text.contains("Werset."))
        XCTAssertFalse(body.text.contains("szum"))
    }

    func testOstatniRozdzialRodzaju() async throws {
        let book = try XCTUnwrap(Book.all.first)
        let html = """
        <p data-chapter="49">Przed granicą</p>
        <p data-chapter="49" class="inicjal2znaki"><span class="num">5</span><span class="num">0</span></p>
        <p data-chapter="49">Za granicą</p>
        """
        let service = BibleService { _ in Data(html.utf8) }
        let first = try await service.chapter(book, 49), second = try await service.chapter(book, 50)
        XCTAssertFalse(first.text.contains("Za granicą"))
        XCTAssertFalse(second.text.contains("Przed granicą"))
        XCTAssertTrue(second.text.contains("Za granicą"))
    }

    func testBrakiIDaneBledne() async {
        for json in ["[]", "{}", #"{"1":{"url":"https://example.org/czytanie/"}}"#] {
            var date = ReadingDate()
            date.day = 1
            do {
                _ = try await BibleService { _ in Data(json.utf8) }.liturgy(date, .all)
                XCTFail("Zaakceptowano błędny kalendarz.")
            } catch { XCTAssertTrue(error is ReaderError) }
        }
    }
    func testPaginacja() async throws {
        let html = """
        <h2>Wyniki wyszukiwania</h2><a class="search-item"><strong>Odsyłacz</strong><div>Chleb &amp; woda</div></a>
        <a class="next page-numbers" href="/szukaj/2/">Dalej</a><a class="prev page-numbers" href="https://example.org/szukaj/1/">Wstecz</a>
        """
        let service = BibleService { url in
            XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "łaska + chleb")
            return Data(html.utf8)
        }
        let page = try await service.search("łaska + chleb")
        XCTAssertEqual(page.items, ["Odsyłacz\nChleb & woda"])
        XCTAssertNil(page.previous)
        XCTAssertEqual(page.next?.host, "twojabiblia.pl")
    }
    func testCytat() async throws {
        let service = BibleService { url in
            XCTAssertTrue(url.absoluteString.hasSuffix("/MA%3D%3D"))
            return Data(#"{"status":"200","body_response":{"book":"Księga","siglum":"<a>Ps 1</a>","content":"Słowo"}}"#.utf8)
        }
        let reading = try await service.quote("Losowo")
        XCTAssertTrue(reading.text.contains("Księga — Ps 1\n\nSłowo"))
    }
}
