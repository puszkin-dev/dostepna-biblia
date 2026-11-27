import XCTest
@testable import Biblia

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
