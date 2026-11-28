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
    var verses: [Verse] = []

    struct Verse: Equatable {
        let number: Int
        let offset: Int
    }

    func writeTXT(in directory: URL) throws -> URL {
        let filename = name.replacingOccurrences(of: "/", with: "-") + ".txt"
        let url = directory.appendingPathComponent(filename)
        try Data(text.utf8).write(to: url, options: .atomic)
        return url
    }
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
    var isHolySaturday: Bool {
        guard month == 3 || month == 4 else { return false }
        // Wielkanoc gregoriańska: algorytm Meeusa, Jonesa i Butchera.
        let cycle = year % 19, century = year / 100, withinCentury = year % 100
        let correction = (century - (century + 8) / 25 + 1) / 3
        let moon = (19 * cycle + century - century / 4 - correction + 15) % 30
        let weekday = (32 + 2 * (century % 4) + 2 * (withinCentury / 4) - moon - withinCentury % 4) % 7
        let offset = moon + weekday - 7 * ((cycle + 11 * moon + 22 * weekday) / 451) + 114
        let easterMonth = offset / 31, easterDay = offset % 31 + 1
        if easterDay == 1 { return month == 3 && day == 31 }
        return month == easterMonth && day == easterDay - 1
    }

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
        guard url.scheme == "https", let host = url.host, ["twojabiblia.pl", "liturgia.wiara.pl"].contains(host) else {
            throw ReaderError("Niepoprawny adres źródła.")
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        for attempt in 0...1 {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
              http.url?.scheme == "https", http.url?.host == host else {
                throw ReaderError("Niepoprawna odpowiedź serwisu \(host).")
            }
            if (200..<300).contains(http.statusCode) { return data }
            if http.statusCode == 429 {
                if attempt == 0, let value = http.value(forHTTPHeaderField: "Retry-After"),
                   let seconds = Int(value), (1...5).contains(seconds) {
                    try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
                    continue
                }
                throw ReaderError("Serwis \(host) chwilowo ogranicza liczbę pobrań. Spróbuj ponownie za chwilę.")
            }
            throw ReaderError("Serwis \(host) zwrócił błąd \(http.statusCode). Spróbuj ponownie.")
        }
        throw ReaderError("Serwis jest chwilowo niedostępny.")
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
        var paragraphs = [date.title]
        let name = "\(date.iso) - \(part.rawValue)"
        let published = try await publishedLiturgy(date)
        if date.isHolySaturday {
            let note = "W Wielką Sobotę Kościół trwa przy grobie Pana i w ciągu dnia nie sprawuje Mszy Świętej. Po zapadnięciu zmroku rozpoczyna się Wigilia Paschalna, która należy już do Niedzieli Zmartwychwstania Pańskiego."
            paragraphs.append(note + (published == nil
                ? " TwojaBiblia.pl nie udostępnia na tę datę czytań Wigilii Paschalnej."
                : " Poniżej znajdziesz czytania Wigilii Paschalnej."))
        }
        if let published {
            if date.month == 12 && date.day == 25 {
                paragraphs += try await christmasReadings(date, published: published, part: part)
            } else {
                paragraphs += [try Self.select(published, part), Self.source]
            }
        } else if !date.isHolySaturday {
            throw ReaderError("TwojaBiblia.pl nie udostępnia czytań dla tej daty.")
        }
        return Reading(name: name, text: paragraphs.joined(separator: "\n\n"))
    }

    private func publishedLiturgy(_ date: ReadingDate) async throws -> String? {
        let calendarURL = try address("/wp-json/post-calendar/v1/month", [
            URLQueryItem(name: "year", value: String(date.year)), URLQueryItem(name: "month", value: String(date.month))])
        let data = try await fetch(calendarURL)
        let calendar = try JSONSerialization.jsonObject(with: data)
        if let empty = calendar as? [Any], empty.isEmpty { return nil }
        guard let days = calendar as? [String: Any] else { throw ReaderError("Niepoprawny kalendarz czytań.") }
        guard let entry = days[String(date.day)] else { return nil }
        guard let fields = entry as? [String: Any], let link = fields["url"] as? String,
              let url = URL(string: link), url.scheme == "https", url.host == "twojabiblia.pl",
              url.path.hasPrefix("/czytanie/" + date.iso.replacingOccurrences(of: "-", with: "/") + "/") else {
            throw ReaderError("Adres czytań nie zgadza się z wybraną datą.")
        }
        let page = try await document(url)
        let justified = try page.select("div[style]").filter {
            try $0.attr("style").lowercased().filter { !$0.isWhitespace }.contains("text-align:justify")
        }
        for node in justified + (try page.select("div[itemprop=text]").array()) {
            let text = try plain(node)
            guard text.localizedCaseInsensitiveContains("psalm"), text.localizedCaseInsensitiveContains("ewangelia") else { continue }
            let notice = #"(?im)(?:^W wigilię [^\n]*?Msza Święta wigilijna tej uroczystości\.[ \t\n]*)?Jeśli chcesz zapoznać się z[^\n]*?kliknij[ \t]+TUTAJ\.?[ \t]*\n*"#
            return text.replacingOccurrences(of: notice, with: "", options: .regularExpression)
        }
        throw ReaderError("Strona zmieniła układ lub nie zawiera pełnego tekstu czytań.")
    }

    private func christmasReadings(_ date: ReadingDate, published: String, part: Part) async throws -> [String] {
        let titles = ["Msza o świcie", "Msza w dzień"]
        var text = published
        var added: [String] = [], missing: [String] = []
        guard let indexURL = URL(string: "https://liturgia.wiara.pl/kalendarz/67b53.Czytania-mszalne/" + date.iso) else {
            throw ReaderError("Niepoprawny adres lekcjonarza.")
        }
        let lines = published.components(separatedBy: .newlines)
        let needed = titles.filter { title in
            !lines.contains { $0.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(title) == .orderedSame }
        }
        if needed.isEmpty { return [try Self.select(text, part, labelMass: true), Self.source] }
        let index: Document
        do {
            index = try await document(indexURL)
        } catch {
            try Task.checkCancellation()
            return [try Self.select(text, part, labelMass: true), Self.missingMasses(needed), Self.source]
        }
        for title in needed {
            do {
                let reading = try await christmasMass(title, index: index, base: indexURL)
                let section = title.uppercased() + "\n\n" + reading
                if title == titles[0], let day = text.range(of: #"(?im)^MSZA W DZIEŃ[ \t]*$"#, options: .regularExpression) {
                    text.insert(contentsOf: section + "\n\n", at: day.lowerBound)
                } else {
                    text += "\n\n" + section
                }
                added.append(title)
            } catch {
                try Task.checkCancellation()
                missing.append(title)
            }
        }
        var result = [try Self.select(text, part, labelMass: true)]
        if !missing.isEmpty {
            result.append(Self.missingMasses(missing))
        }
        result.append(Self.source)
        if !added.isEmpty {
            result.append("Źródło dodatkowych czytań (" + added.joined(separator: ", ") + "): liturgia.wiara.pl, lekcjonarz z 2015 roku.")
        }
        return result
    }

    private static func missingMasses(_ titles: [String]) -> String {
        "Nie udało się pobrać: " + titles.joined(separator: ", ") + ". Pokazano dostępne czytania."
    }

    private func christmasMass(_ title: String, index: Document, base: URL) async throws -> String {
        let invalid = ReaderError("Serwis liturgia.wiara.pl nie udostępnił pełnych czytań: " + title + ".")
        let links = try index.select("a[href]")
        guard let link = try links.first(where: {
            try $0.text().components(separatedBy: "-").last?.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(title) == .orderedSame
        }), let url = try URL(string: link.attr("href"), relativeTo: base)?.absoluteURL,
              url.scheme == "https", url.host == base.host,
              url.deletingLastPathComponent().path == base.path, Int(url.lastPathComponent) != nil,
              let anchor = url.fragment, anchor.range(of: #"^Par[0-9]+$"#, options: .regularExpression) != nil else { throw invalid }
        let page = try await document(url)
        guard let mark = try page.select("a[name=\(anchor)]").first(),
              let block = mark.parents().first(where: { $0.hasClass("txt__rich-area") }) else { throw invalid }
        try mark.remove()
        for heading in try block.select("p.block-title") {
            guard let verse = try heading.nextElementSibling(), verse.hasClass("bible-verse") else { continue }
            try heading.text(heading.text() + " (" + verse.text() + ")")
            try verse.remove()
        }
        let text = try plain(block)
        guard text.localizedCaseInsensitiveContains("psalm"), text.localizedCaseInsensitiveContains("ewangelia") else { throw invalid }
        return text
    }

    static func select(_ text: String, _ part: Part, labelMass: Bool = false) throws -> String {
        guard part != .all else { return text }
        // Grupy 1–5 odpowiadają wybieranym częściom; szósta przechowuje cały tytuł Mszy.
        let pattern = #"(?im)^(?:(PIERWSZE CZYTANIE|I CZYTANIE)|(DRUGIE CZYTANIE|II CZYTANIE)|"#
            + #"((?:\d+[ \t]+)?(?:PSALM RESPONSORYJNY|PSALM))|(ŚPIEW PRZED EWANGELIĄ|AKLAMACJA)|(EWANGELIA)|"#
            + #"(?:TRZECIE|CZWARTE|PIĄTE|SZÓSTE|SIÓDME|ÓSME) CZYTANIE)"#
            + #"(?=[ \t]*(?:\(|\r?$|[–:])|[ \t]+(?:W CZASIE|DŁUŻSZA|KRÓTSZA|WERSJA)\b)|"#
            + #"^(MSZA(?=[ \t(–:]|$)(?-i:[^\n\p{Ll}]*)|MSZA[ \t]*(?:\(|[–:]|W CZASIE\b)[^\n]*)(?=\r?$)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let group = Part.allCases.firstIndex(of: part) ?? 0
        var sections: [String] = []
        let includeMassTitles = labelMass || matches.filter { $0.range(at: 6).location != NSNotFound }.count > 1
        var mass: String?
        for (i, match) in matches.enumerated() {
            if match.range(at: 6).location != NSNotFound {
                mass = ns.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }
            guard match.range(at: group).location != NSNotFound else { continue }
            if includeMassTitles, let title = mass {
                sections.append(title)
                mass = nil
            }
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
            if node.hasClass("inicjal2znaki"), try node.text().allSatisfy({ $0.isNumber || $0.isWhitespace }) { continue }
            if number > 0 {
                for mark in try node.select("span.num") {
                    let value = try mark.text()
                    if let verse = Int(value), verse > 0 {
                        try mark.text("\u{E000}" + value + "\u{E001}")
                    }
                }
            }
            let text = try plain(node)
            if !text.isEmpty { paragraphs.append(text) }
        }
        guard !paragraphs.isEmpty else { throw ReaderError("TwojaBiblia.pl nie udostępnia tekstu tego rozdziału.") }
        let title = book.name + (number == 0 ? " — wstęp" : " — rozdział \(number)")
        if shared { paragraphs.insert("Wspólny wstęp do Listów św. Jana.", at: 0) }
        let marked = ([title] + paragraphs + [Self.source + "\n" + url.absoluteString]).joined(separator: "\n\n") as NSString
        let markers = try NSRegularExpression(pattern: "\u{E000}([0-9]+)\u{E001}")
        let clean = NSMutableString(capacity: marked.length)
        var verses: [Reading.Verse] = []
        var position = 0
        for match in markers.matches(in: marked as String, range: NSRange(location: 0, length: marked.length)) {
            clean.append(marked.substring(with: NSRange(location: position, length: match.range.location - position)))
            let digits = marked.substring(with: match.range(at: 1))
            if let value = Int(digits), value > (verses.last?.number ?? 0) {
                verses.append(.init(number: value, offset: clean.length))
            }
            clean.append(digits)
            position = NSMaxRange(match.range)
        }
        clean.append(marked.substring(from: position))
        return Reading(name: title, text: clean as String, verses: verses)
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
