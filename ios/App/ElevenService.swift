import Foundation
import Security
import CryptoKit

enum ElevenKey {
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.dostepna.biblia.elevenlabs",
         kSecAttrAccount as String: "api"]
    }
    static func read() throws -> String? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data, let key = String(data: data, encoding: .utf8)
        else { throw ReaderError("Nie można odczytać klucza z pęku kluczy iPhone’a.") }
        return key
    }
    static func save(_ key: String) throws {
        let attributes: [String: Any] = [kSecValueData as String: Data(key.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw ReaderError("Nie udało się zapisać klucza na iPhonie.") }
    }
    static func remove() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw ReaderError("Nie udało się usunąć klucza.") }
    }
}

struct ElevenVoice: Codable {
    let voice_id: String
    let name: String
}

final class ElevenNetwork: NSObject, URLSessionTaskDelegate {
    static let shared = ElevenNetwork()
    static let model = "eleven_v4"
    static let format = "mp3_44100_128"
    let configuration: URLSessionConfiguration = {
        let value = URLSessionConfiguration.ephemeral
        value.urlCache = nil
        value.httpShouldSetCookies = false
        value.urlCredentialStorage = nil
        value.timeoutIntervalForRequest = 60
        return value
    }()
    lazy var session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }

    private func request(path: String, query: [URLQueryItem], key: String) throws -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "api.elevenlabs.io"
        parts.path = path
        parts.queryItems = query
        guard let url = parts.url else { throw ReaderError("Niepoprawny adres usługi mowy.") }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        return request
    }

    func voices(key: String) async throws -> [ElevenVoice] {
        guard !key.isEmpty, !key.contains(where: { $0.isWhitespace || $0.isNewline }) else {
            throw ReaderError("Wpisz klucz API ElevenLabs bez spacji.")
        }
        struct Page: Decodable {
            let voices: [ElevenVoice]
            let has_more: Bool
            let next_page_token: String?
        }
        var token: String?
        var pages = Set<String>()
        var seen = Set<String>()
        var voices: [ElevenVoice] = []
        repeat {
            var query = [URLQueryItem(name: "page_size", value: "100")]
            if let token { query.append(URLQueryItem(name: "next_page_token", value: token)) }
            let request = try request(path: "/v2/voices", query: query, key: key)
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            try Self.check(response, body: data)
            let page = try JSONDecoder().decode(Page.self, from: data)
            voices += page.voices.filter { !$0.voice_id.isEmpty && seen.insert($0.voice_id).inserted }
            if !page.has_more { break }
            guard let next = page.next_page_token, !next.isEmpty, pages.insert(next).inserted else {
                throw ReaderError("ElevenLabs zwróciło niepełną listę głosów. Spróbuj ponownie.")
            }
            token = next
        } while true
        return voices.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func speech(text: String, voice: String, key: String) throws -> URLRequest {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        guard !voice.isEmpty, voice.unicodeScalars.allSatisfy(allowed.contains) else {
            throw ReaderError("Niepoprawny identyfikator głosu ElevenLabs. Odśwież listę głosów.")
        }
        var request = try request(path: "/v1/text-to-speech/\(voice)/stream",
                                  query: [.init(name: "output_format", value: Self.format)], key: key)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model_id": Self.model, "language_code": "pl", "text": text
        ])
        return request
    }

    static func check(_ response: URLResponse?, body: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw ReaderError("Brak odpowiedzi ElevenLabs.") }
        guard !(200..<300).contains(http.statusCode) else { return }
        let object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
        let fields = [object, object?["detail"] as? [String: Any], object?["error"] as? [String: Any]]
        let codes = fields.compactMap { $0 }.flatMap { [$0["status"], $0["code"], $0["type"]] }.compactMap { $0 as? String }
        let code = codes.joined(separator: " ").lowercased()
        let message: String
        if code.contains("quota") || code.contains("credit") || http.statusCode == 402 {
            message = "Brak kredytów lub wyczerpany limit wydatków ElevenLabs."
        } else if code.contains("permission") || code.contains("authorization_error") || http.statusCode == 403 {
            message = "Klucz nie ma wymaganych uprawnień. Sprawdź dostęp do głosów i generowania mowy."
        } else if http.statusCode == 401 || code.contains("invalid_api_key") {
            message = "Klucz ElevenLabs jest błędny lub wygasł."
        } else if http.statusCode == 429 || code.contains("concurrent") || code.contains("rate_limit") {
            message = "ElevenLabs ograniczyło liczbę żądań. Spróbuj później."
        } else {
            message = "ElevenLabs nie wykonało żądania (kod \(http.statusCode)). Nie ponowiono go automatycznie."
        }
        throw ReaderError(message)
    }
    static func message(_ error: Error) -> String {
        if let known = error as? ReaderError { return known.message }
        if error is URLError { return "Nie udało się połączyć z ElevenLabs. Sprawdź internet i spróbuj ponownie." }
        return "Nie udało się odczytać danych ElevenLabs lub zapisać ich na iPhonie."
    }
}

enum ElevenText {
    static func clean(_ source: String) -> String {
        var text = source.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        for (pattern, replacement) in [
            (#"!?\[([^\]\n]+)\]\((?:https?://|mailto:)[^\s)]+\)"#, "$1"),
            (#"(?i)(?:https?://|www\.)[^\s<>]+(?<![.,;:!?)])"#, ""),
            (#"(?i)<br\s*/?>|</p\s*>"#, "\n"),
            (#"(?i)</?(?:p|div|span|strong|em|b|i|a|h[1-6]|li|ul|ol|blockquote)(?:\s+[^>\n]*)?/?>"#, ""),
            (#"(?m)^[ \t]*(?:#{1,6}[ \t]+|>[ \t]*|[-+][ \t]+)"#, ""),
            (#"(?m)^[ \t]*(?:[-=_*]{3,})[ \t]*$"#, ""),
            (#"(?m)^[ \t]*\x60{3,}[a-zA-Z0-9_-]*[ \t]*$"#, ""),
            (#"(?<![\p{L}\p{N}])_{1,3}(.+?)_{1,3}(?![\p{L}\p{N}])"#, "$1"),
            (#"[*\x60]|~~"#, ""), (#"[ \t]{2,}"#, " "), (#"\n[ \t]*\n(?:[ \t]*\n)+"#, "\n\n")
        ] {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return text.replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Krótsza porcja ogranicza koszt przerwania i ilość dźwięku oczekującego na odsłuch.
    static func chunks(_ text: String) -> [String] {
        let scalars = text.unicodeScalars
        var start = scalars.startIndex
        var result: [String] = []
        while start < scalars.endIndex {
            let limit = scalars.index(start, offsetBy: 2000, limitedBy: scalars.endIndex) ?? scalars.endIndex
            var end = limit
            if limit < scalars.endIndex {
                let window = scalars[start..<limit]
                if let paragraph = window.lastIndex(of: "\n") {
                    end = scalars.index(after: paragraph)
                } else if let sentence = window.indices.last(where: { index in
                    ".!?…".unicodeScalars.contains(scalars[index]) &&
                        CharacterSet.whitespacesAndNewlines.contains(scalars[scalars.index(after: index)])
                }) {
                    end = scalars.index(after: sentence)
                } else if let space = window.lastIndex(where: CharacterSet.whitespacesAndNewlines.contains) {
                    end = scalars.index(after: space)
                }
            }
            let part = String(scalars[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !part.isEmpty { result.append(part) }
            start = end
        }
        return result
    }

    static func cacheID(text: String, voice: String) -> String {
        let fields = [ElevenNetwork.model, "pl", ElevenNetwork.format, voice, text]
        let bytes = Data(fields.map { "\($0.utf8.count):\($0)" }.joined().utf8)
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
}
