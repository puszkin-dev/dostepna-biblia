import XCTest
@testable import DostepnaBiblia

/// Próby integracyjne z żywym źródłem; wymagają internetu i dostępnego kalendarza.
final class SourceTests: XCTestCase {
    func testWszystkieCzesciLiturgii() async throws {
        var date = ReadingDate()
        date.year = 2026
        date.month = 11
        date.day = 29
        let whole = try await BibleService().liturgy(date, .all)
        for part in Part.allCases where part != .all {
            let section = try BibleService.select(whole.text, part)
            XCTAssertFalse(section.isEmpty, part.rawValue)
        }
    }

    func testSwietaNaZywychDanych() async throws {
        var date = ReadingDate()
        date.year = 2026
        let service = BibleService()
        for (month, day, part, wanted, unwanted) in [
            (12, 25, Part.gospel, ["MSZA W NOCY", "MSZA O ŚWICIE", "MSZA W DZIEŃ", "liturgia.wiara.pl"], ["kliknij TUTAJ", "PIERWSZE CZYTANIE"]),
            (12, 25, .all, ["MSZA W NOCY", "MSZA O ŚWICIE", "MSZA W DZIEŃ"], ["kliknij TUTAJ", "W wigilię uroczystości"]),
            (6, 24, .all, ["EWANGELIA"], ["kliknij TUTAJ"]),
            (8, 15, .all, ["EWANGELIA"], ["kliknij TUTAJ"]),
            (4, 4, .second, ["W Wielką Sobotę", "DRUGIE CZYTANIE"], ["TRZECIE CZYTANIE", "PSALM RESPONSORYJNY"]),
            (4, 4, .psalm, ["1 PSALM", "2 PSALM"], ["ÓSME CZYTANIE", "EWANGELIA"]),
            (6, 29, .all, ["Mszy wotywnej"], ["kliknij TUTAJ"]),
            (5, 24, .all, ["EWANGELIA"], ["kliknij TUTAJ"])
        ] {
            date.month = month
            date.day = day
            let result = try await service.liturgy(date, part)
            for needle in wanted { XCTAssertTrue(result.text.contains(needle), "\(date.iso): brak \(needle)") }
            for needle in unwanted { XCTAssertFalse(result.text.contains(needle), "\(date.iso): \(needle)") }
            if part == .gospel {
                let headings = result.text.components(separatedBy: .newlines).filter { $0.hasPrefix("EWANGELIA") }
                XCTAssertEqual(headings.count, 4, headings.joined(separator: "; "))
                for reference in ["Łk 2, 1-14", "Łk 2, 15-20", "J 1, 1-18", "J 1, 1-5. 9-14"] {
                    XCTAssertTrue(headings.contains { $0.contains(reference) }, headings.joined(separator: "; "))
                }
            }
        }
    }

    func testWstepJanaIOstatniRozdzialRodzaju() async throws {
        let service = BibleService()
        let john = try XCTUnwrap(Book.all.first { $0.code == "3-J" })
        let intro = try await service.chapter(john, 0)
        XCTAssertTrue(intro.text.contains("Wspólny wstęp"))
        let genesis = try XCTUnwrap(Book.all.first)
        let final = try await service.chapter(genesis, 50)
        XCTAssertTrue(final.text.contains("/Rdz/49/"))
        XCTAssertEqual(final.verses.prefix(7).map(\.number), Array(1...7))
        XCTAssertGreaterThan(final.text.count, 1000)
    }

    func testKategorieCytatow() async throws {
        let service = BibleService()
        for category in BibleService.categories {
            let quote = try await service.quote(category)
            XCTAssertTrue(quote.text.contains(" — "), category)
        }
    }

    func testStronyIPustaFraza() async throws {
        let service = BibleService()
        let page = try await service.search("chleb")
        XCTAssertFalse(page.items.isEmpty)
        let next = try XCTUnwrap(page.next)
        let second = try await service.search("chleb", page: next)
        XCTAssertNotEqual(page.items, second.items)
        XCTAssertNotNil(second.previous)
        let empty = try await service.search("nieistniejaceslowobibliatest")
        XCTAssertTrue(empty.items.isEmpty)
    }
}
