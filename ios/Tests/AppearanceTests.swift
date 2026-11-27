import XCTest
import UIKit
@testable import DostepnaBiblia

final class AppearanceTests: XCTestCase {
    func testUstawienieICzynnikiSystemowe() throws {
        let id = "test.biblia.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: id))
        defer { defaults.removePersistentDomain(forName: id) }
        let size = ReadingSize(defaults: defaults)
        XCTAssertEqual(size.index, 1)
        let normal = UITraitCollection(preferredContentSizeCategory: .large)
        let largest = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let standard = size.font(normal).pointSize
        size.index = 4
        XCTAssertEqual(ReadingSize(defaults: defaults).index, 4)
        XCTAssertGreaterThan(size.font(normal).pointSize, standard)
        XCTAssertGreaterThan(size.font(largest).pointSize, size.font(normal).pointSize)
        XCTAssertEqual(size.font(largest).pointSize, UIFontMetrics(forTextStyle: .body)
            .scaledValue(for: ReadingSize.points[4], compatibleWith: largest), accuracy: 1)
        size.index = -1
        XCTAssertEqual(size.index, 4)
        defaults.set(100, forKey: ReadingSize.key)
        XCTAssertEqual(size.index, ReadingSize.standard)
        let bold = UITraitCollection(legibilityWeight: .bold)
        XCTAssertTrue(size.font(bold).fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testKontrastPalety() {
        for style: UIUserInterfaceStyle in [.light, .dark] {
            for contrast: UIAccessibilityContrast in [.normal, .high] {
                let traits = UITraitCollection { $0.userInterfaceStyle = style; $0.accessibilityContrast = contrast }
                func light(_ color: UIColor) -> CGFloat {
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    XCTAssertTrue(color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a))
                    func linear(_ value: CGFloat) -> CGFloat {
                        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
                    }
                    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
                }
                let pairs: [(UIColor, UIColor, CGFloat)] = [
                    (BookStyle.ink, BookStyle.paper, 4.5), (BookStyle.ink, BookStyle.surface, 4.5),
                    (BookStyle.accent, BookStyle.paper, 4.5), (BookStyle.onAccent, BookStyle.accent, 4.5),
                    (BookStyle.track, BookStyle.surface, 3)
                ]
                for (foreground, background, minimum) in pairs {
                    let f = light(foreground), b = light(background)
                    XCTAssertGreaterThanOrEqual((max(f, b) + 0.05) / (min(f, b) + 0.05), minimum)
                }
            }
        }
    }

    func testPozycjeWersetowIUtrzymanieEksportu() async throws {
        let source = """
        <p data-chapter="1"><span class="num">1</span> Światło 🌿 <span class="num">2</span> Drugi.
        <span class="footnote-trigger"><span class="num">3</span> Przypis.</span></p>
        """
        let book = try XCTUnwrap(Book.all.first)
        let reading = try await BibleService { _ in Data(source.utf8) }.chapter(book, 1)
        XCTAssertEqual(reading.verses.map(\.number), [1, 2])
        XCTAssertFalse(reading.text.contains("\u{E000}"))
        let second = try XCTUnwrap(reading.verses.last)
        XCTAssertTrue((reading.text as NSString).substring(from: second.offset).hasPrefix("2"))
        XCTAssertTrue(reading.excerpt(second).hasPrefix("Drugi."))
    }
}
