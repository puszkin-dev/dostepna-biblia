import Foundation
import SwiftSoup

struct ReaderError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

struct Reading: Equatable {
    let name: String
    let text: String
}

struct ReadingDate: Equatable {
    static let months = ["styczeń", "luty", "marzec", "kwiecień", "maj", "czerwiec",
                         "lipiec", "sierpień", "wrzesień", "październik", "listopad", "grudzień"]
    static let calendar = Calendar(identifier: .gregorian)
    var year: Int
    var month: Int
    var day: Int

    init(_ date: Date = Date()) {
        let parts = Self.calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year ?? 2000
        month = parts.month ?? 1
        day = parts.day ?? 1
    }

    var lastDay: Int {
        let first = DateComponents(calendar: Self.calendar, year: year, month: month, day: 1)
        return first.date.flatMap { Self.calendar.range(of: .day, in: .month, for: $0)?.count } ?? 28
    }
    mutating func clampDay() { day = min(max(day, 1), lastDay) }
    var iso: String { String(format: "%04d-%02d-%02d", year, month, day) }
    var title: String {
        let formatter = DateFormatter()
        formatter.calendar = Self.calendar
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        let date = DateComponents(calendar: Self.calendar, year: year, month: month, day: day).date
        return date.map(formatter.string(from:)) ?? iso
    }
}

enum Part: String, CaseIterable {
    case all = "Cała liturgia", first = "Pierwsze czytanie", second = "Drugie czytanie"
    case psalm = "Psalm", acclamation = "Aklamacja", gospel = "Ewangelia"
}

struct SearchPage {
    let items: [String]
    let previous: URL?
    let next: URL?
}

struct BibleService {
    typealias Fetch = (URL) async throws -> Data
    let fetch: Fetch
    static let source = "Źródło: TwojaBiblia.pl. Biblia Tysiąclecia, wydanie V."
    static let categories = ["Losowo", "Zagrzewające do życia i pracy", "Kiedy jest mi smutno",
                             "Na dobry dzień", "Kiedy brak mi sił"]

    init(fetch: @escaping Fetch = BibleService.download) { self.fetch = fetch }

    static func download(_ url: URL) async throws -> Data {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              http.url?.scheme == "https", http.url?.host == "twojabiblia.pl" else {
            throw ReaderError("Serwis TwojaBiblia.pl nie zwrócił treści. Spróbuj ponownie.")
        }
        return data
    }

    private func address(_ path: String, _ query: [URLQueryItem] = []) throws -> URL {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "twojabiblia.pl"
        parts.percentEncodedPath = path
        if !query.isEmpty {
            parts.queryItems = query
            parts.percentEncodedQuery = parts.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = parts.url else { throw ReaderError("Niepoprawny adres źródła.") }
        return url
    }

    private func document(_ url: URL) async throws -> Document {
        let data = try await fetch(url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ReaderError("Nie udało się odczytać kodowania strony.")
        }
        return try SwiftSoup.parse(html, url.absoluteString)
    }

    private func plain(_ node: Element) throws -> String {
        var html = try node.html()
        func replace(_ pattern: String, _ value: String) {
            html = html.replacingOccurrences(of: pattern, with: value, options: .regularExpression)
        }
        replace(#"(?is)<!--.*?-->|<(script|style)\b[^>]*>.*?</\1\s*>"#, "")
        replace(#"\s+"#, " ")
        replace(#"(?i)<br\b[^>]*>"#, "\n")
        replace(#"(?i)</(?:p|div|li|h[1-6])\s*>"#, "\n\n")
        replace("<[^>]*>", "")
        html = try Entities.unescape(html).replacingOccurrences(of: "\u{a0}", with: " ")
        replace(#"[ \t]*\n[ \t]*"#, "\n")
        replace(#"\n{3,}"#, "\n\n")
        return html.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func liturgy(_ date: ReadingDate, _ part: Part) async throws -> Reading {
        let calendarURL = try address("/wp-json/post-calendar/v1/month", [
            URLQueryItem(name: "year", value: String(date.year)), URLQueryItem(name: "month", value: String(date.month))])
        let data = try await fetch(calendarURL)
        let calendar = try JSONSerialization.jsonObject(with: data)
        let missing = ReaderError("TwojaBiblia.pl nie udostępnia czytań dla tej daty.")
        if let empty = calendar as? [Any], empty.isEmpty { throw missing }
        guard let days = calendar as? [String: Any] else { throw ReaderError("Niepoprawny kalendarz czytań.") }
        guard let entry = days[String(date.day)] else { throw missing }
        guard let fields = entry as? [String: Any], let link = fields["url"] as? String,
              let url = URL(string: link), url.scheme == "https", url.host == "twojabiblia.pl",
              url.path.hasPrefix("/czytanie/" + date.iso.replacingOccurrences(of: "-", with: "/") + "/") else {
            throw ReaderError("Adres czytań nie zgadza się z wybraną datą.")
        }
        let page = try await document(url)
        for node in try page.select("div[style]") {
            let style = try node.attr("style").lowercased().filter { !$0.isWhitespace }
            guard style.contains("text-align:justify") else { continue }
            let text = try plain(node)
            guard text.localizedCaseInsensitiveContains("psalm"), text.localizedCaseInsensitiveContains("ewangelia") else { continue }
            let body = try Self.select(text, part)
            return Reading(name: "\(date.iso) - \(part.rawValue)", text: "\(date.title)\n\n\(body)\n\n\(Self.source)")
        }
        throw ReaderError("Strona zmieniła układ lub nie zawiera pełnego tekstu czytań.")
    }

    static func select(_ text: String, _ part: Part) throws -> String {
        guard part != .all else { return text }
        let pattern = #"(?im)^(?:(PIERWSZE CZYTANIE|I CZYTANIE)|(DRUGIE CZYTANIE|II CZYTANIE)|(PSALM RESPONSORYJNY|PSALM)|(ŚPIEW PRZED EWANGELIĄ|AKLAMACJA)|(EWANGELIA)|MSZA)(?=[ \t]*(?:\(|\r?$|[–:])|[ \t]+(?:W CZASIE|DŁUŻSZA|KRÓTSZA|WERSJA)\b)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let group = Part.allCases.firstIndex(of: part) ?? 0
        var sections: [String] = []
        for (i, match) in matches.enumerated() where match.range(at: group).location != NSNotFound {
            let end = i + 1 < matches.count ? matches[i + 1].range.location : ns.length
            sections.append(ns.substring(with: NSRange(location: match.range.location, length: end - match.range.location))
                .trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard !sections.isEmpty else { throw ReaderError("Wybrana część liturgii nie jest dostępna dla tej daty.") }
        return sections.joined(separator: "\n\n")
    }

    func chapters(_ book: Book) async throws -> [Int] {
        let page = try await document(address("/czytaj/\(book.code)/1/"))
        var numbers = try page.select(".chapter-selector a").compactMap { try Int($0.text()) }
        guard !numbers.isEmpty else { throw ReaderError("Nie udało się odczytać listy rozdziałów.") }
        if numbers == [0] { numbers.append(1) }
        if book.code == "Rdz", numbers.last == 49 { numbers.append(50) }
        return numbers
    }

    func chapter(_ book: Book, _ number: Int) async throws -> Reading {
        let shared = number == 0 && ["2-J", "3-J"].contains(book.code)
        let code = shared ? "1-J" : book.code
        let combined = ["Ab", "Flm", "Jud", "2-J", "3-J"].contains(code)
        let index = combined ? 0 : (code == "Rdz" && number == 50 ? 49 : number)
        let url = try address("/czytaj/\(code)/\(index)/")
        let page = try await document(url)
        try page.select(".footnote-trigger").remove()
        var paragraphs: [String] = []
        var titles = 0
        let start = ["2-J", "3-J"].contains(code) ? 1 : 2
        var lastChapter = false
        for node in try page.select("p[data-chapter=\(index)]") {
            if node.hasClass("A5-KSIEGATYTUL") {
                titles += 1
                if combined && (number == 0 ? titles == start : titles > start) { break }
                continue
            }
            if combined && number > 0 && titles < start { continue }
            if code == "Rdz", index == 49 {
                if node.hasClass("inicjal2znaki"), try node.select("span.num").map({ try $0.text() }) == ["5", "0"] {
                    lastChapter = true
                    continue
                }
                if lastChapter != (number == 50) { continue }
            }
            guard !node.hasClass("initial") else { continue }
            let text = try plain(node)
            if !text.isEmpty { paragraphs.append(text) }
        }
        guard !paragraphs.isEmpty else { throw ReaderError("TwojaBiblia.pl nie udostępnia tekstu tego rozdziału.") }
        let title = book.name + (number == 0 ? " — wstęp" : " — rozdział \(number)")
        if shared { paragraphs.insert("Wspólny wstęp do Listów św. Jana.", at: 0) }
        return Reading(name: title, text: ([title] + paragraphs + [Self.source + "\n" + url.absoluteString]).joined(separator: "\n\n"))
    }

    func quote(_ category: String) async throws -> Reading {
        let key = Data((category == Self.categories[0] ? "0" : category).utf8).base64EncodedString()
        let component = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let data = try await fetch(address("/wp-json/tbapi/v1/get_quote/" + component))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              String(describing: json["status"] ?? "") == "200", let body = json["body_response"] as? [String: Any] else {
            throw ReaderError("Nie udało się wylosować cytatu.")
        }
        func field(_ name: String) throws -> String {
            guard let html = body[name] as? String else { throw ReaderError("Niepełny cytat.") }
            let text = try SwiftSoup.parseBodyFragment(html).text()
            guard !text.isEmpty else { throw ReaderError("Puste pole cytatu.") }
            return text
        }
        let text = try field("book") + " — " + field("siglum") + "\n\n" + field("content")
        return Reading(name: "Cytat biblijny - \(ReadingDate().iso)", text: text + "\n\nBiblia Tysiąclecia, wydanie V.")
    }

    func search(_ query: String, page link: URL? = nil) async throws -> SearchPage {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ReaderError("Wpisz słowo lub frazę do wyszukania.") }
        let url = try link ?? address("/", [URLQueryItem(name: "s", value: query)])
        let page = try await document(url)
        guard try page.select("h1,h2,h3,h4,h5,h6").contains(where: { try $0.text().lowercased() == "wyniki wyszukiwania" }) else {
            throw ReaderError("Nie udało się odczytać strony wyników TwojaBiblia.pl.")
        }
        let items = try page.select("a.search-item").map { node -> String in
            guard let title = try node.select("strong").first(), let body = try node.select("div").first() else {
                throw ReaderError("Strona zmieniła układ wyników wyszukiwania.")
            }
            return try plain(title) + "\n" + plain(body)
        }
        func pageLink(_ direction: String) throws -> URL? {
            guard let path = try page.select("a.page-numbers." + direction).first()?.attr("href"),
                  let value = URL(string: path, relativeTo: url)?.absoluteURL,
                  value.scheme == "https", value.host == "twojabiblia.pl", value.path.hasPrefix("/szukaj/") else { return nil }
            return value
        }
        return try SearchPage(items: items, previous: pageLink("prev"), next: pageLink("next"))
    }
}
