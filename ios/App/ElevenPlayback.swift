import AVFoundation
import Foundation

struct ElevenBookmark: Codable {
    let id: UUID
    let title: String
    let parts: [String]
    let voice: String
    let model: String
    struct Cursor: Codable {
        let id: UUID
        let index: Int
        let seconds: Double
    }
    private static func directory() throws -> URL {
        let manager = FileManager.default
        var url = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("CzytanieEleven", isDirectory: true)
        try manager.createDirectory(at: url, withIntermediateDirectories: true)
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try url.setResourceValues(flags)
        return url
    }
    static func load() -> (ElevenBookmark, Cursor)? {
        guard let dir = try? directory(),
              let data = try? Data(contentsOf: dir.appendingPathComponent("sesja.json")),
              let book = try? JSONDecoder().decode(Self.self, from: data),
              book.model == ElevenNetwork.model, !book.parts.isEmpty else { return nil }
        if let bytes = try? Data(contentsOf: dir.appendingPathComponent("miejsce.json")),
           let point = try? JSONDecoder().decode(Cursor.self, from: bytes),
           point.id == book.id, book.parts.indices.contains(point.index), point.seconds.isFinite, point.seconds >= 0 {
            return (book, point)
        }
        return (book, Cursor(id: book.id, index: 0, seconds: 0))
    }
    func save() throws {
        try JSONEncoder().encode(self).write(to: Self.directory().appendingPathComponent("sesja.json"),
                                              options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    func save(index: Int, seconds: Double) throws {
        try JSONEncoder().encode(Cursor(id: id, index: index, seconds: seconds))
            .write(to: Self.directory().appendingPathComponent("miejsce.json"),
                   options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    static func clear() throws {
        let dir = try directory()
        for name in ["sesja.json", "miejsce.json"] {
            let url = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
    }
}

/// Sprawdza kompletność ramek zamówionego MP3 44,1 kHz także przy HTTP bez Content-Length.
enum ElevenMP3 {
    static func complete(_ data: Data) -> Bool {
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let b = raw.bindMemory(to: UInt8.self)
            var i = 0
            let end = b.count
            if end >= 10 && b[0] == 73 && b[1] == 68 && b[2] == 51 {
                var size = 0
                for j in 6...9 {
                    guard b[j] < 128 else { return false }
                    size = size * 128 + Int(b[j])
                }
                i = 10 + size + (b[3] == 4 && b[5] & 16 != 0 ? 10 : 0)
            }
            let rates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
            var frames = 0
            while i < end {
                if end - i == 128 && b[i] == 84 && b[i + 1] == 65 && b[i + 2] == 71 { return frames > 0 }
                guard end - i >= 4, b[i] == 255, b[i + 1] & 0xfe == 0xfa, b[i + 2] & 12 == 0 else { return false }
                let rate = rates[Int(b[i + 2] >> 4)]
                let length = 144_000 * rate / 44_100 + Int((b[i + 2] >> 1) & 1)
                guard rate != 0, length <= end - i else { return false }
                i += length
                frames += 1
            }
            return i == end && frames > 0
        }
    }
}

/// Jeden POST i jeden plik tymczasowy. Obsługa danych i przejęcie bufora przez czytnik są na tej samej kolejce.
private final class ElevenTransfer: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let final: URL
    let partial: URL
    private var file: FileHandle?
    private var session: URLSession?
    private var response: HTTPURLResponse?
    private var errorBody = Data()
    private var bytes: Int64 = 0
    var failure: Error?
    var onBytes: ((Data) throws -> Void)?
    var onFinish: ((Error?) -> Void)?

    init(destination: URL) {
        final = destination
        partial = destination.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".part.mp3")
    }

    func start(_ request: URLRequest) throws {
        guard FileManager.default.createFile(atPath: partial.path, contents: nil) else {
            throw ReaderError("Nie można przygotować pliku dźwięku na iPhonie.")
        }
        file = try FileHandle(forWritingTo: partial)
        let session = URLSession(configuration: ElevenNetwork.shared.configuration, delegate: self, delegateQueue: .main)
        self.session = session
        session.dataTask(with: request).resume()
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard self.session != nil, let response else { return }
        if !(200..<300).contains(response.statusCode) {
            errorBody.append(data.prefix(max(0, 8192 - errorBody.count)))
            return
        }
        do {
            try file?.write(contentsOf: data)
            bytes += Int64(data.count)
            try onBytes?(data)
        } catch { finish(error) }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard self.session != nil else { return }
        do {
            if let error { throw error }
            try ElevenNetwork.check(response, body: errorBody)
            try file?.close()
            file = nil
            let expected = response?.expectedContentLength ?? -1
            guard bytes > 0, expected < 0 || expected == bytes,
                  let content = try? Data(contentsOf: partial, options: .mappedIfSafe), ElevenMP3.complete(content),
                  let audio = try? AVAudioFile(forReading: partial), audio.length > 0 else {
                throw ReaderError("Nagranie ElevenLabs jest niekompletne. Nie zapisano go w pamięci podręcznej.")
            }
            try FileManager.default.moveItem(at: partial, to: final)
            finish(nil)
        } catch { finish(error) }
    }
    /// Dopina odbiorcę do już pobieranego następnego fragmentu bez kolejnego POST.
    func attach(_ handle: @escaping (Data) throws -> Void) throws {
        if bytes > 0 { try Self.read(partial, into: handle) }
        onBytes = handle
    }
    static func read(_ url: URL, into consume: (Data) throws -> Void) throws {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        while let part = try handle.read(upToCount: 16_384), !part.isEmpty { try consume(part) }
    }
    private func finish(_ error: Error?) {
        let callback = onFinish
        failure = error
        cancel()
        callback?(error)
    }
    func cancel() {
        onFinish = nil
        onBytes = nil
        session?.invalidateAndCancel()
        session = nil
        try? file?.close()
        file = nil
        try? FileManager.default.removeItem(at: partial)
    }
}

final class ElevenPlayback {
    private let book: ElevenBookmark
    private let remember: Bool
    private let settings: SpeechPreferences
    private let directory: URL
    private var index: Int
    private var offset: Double
    private var audio: ElevenAudio?
    private var transfers: [String: ElevenTransfer] = [:]
    private var timer: Timer?
    private var stopped = false
    var preparing: (() -> Void)?
    var started: (() -> Void)?
    var finished: ((Error?) -> Void)?

    init(book: ElevenBookmark, index: Int, seconds: Double, remember: Bool, settings: SpeechPreferences) throws {
        self.book = book
        self.index = index
        offset = seconds
        self.remember = remember
        self.settings = settings
        directory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ElevenMP3", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Po zabiciu procesu żaden plik .part nie jest gotowym nagraniem.
        for item in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        where item.lastPathComponent.hasSuffix(".part.mp3") { try? FileManager.default.removeItem(at: item) }
    }
    func start() throws {
        if remember {
            try book.save()
            try book.save(index: index, seconds: offset)
            timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.checkpoint() }
        }
        try playCurrent()
    }
    func checkpoint() {
        guard remember, !stopped else { return }
        do { try book.save(index: index, seconds: audio?.position ?? offset) }
        catch { fail(ReaderError("Nie udało się zapamiętać miejsca czytania na iPhonie.")) }
    }
    private func address(_ position: Int) -> URL {
        directory.appendingPathComponent(ElevenText.cacheID(text: book.parts[position], voice: book.voice) + ".mp3")
    }
    private func transfer(_ position: Int) throws -> ElevenTransfer {
        let url = address(position)
        if let existing = transfers[url.lastPathComponent] {
            if let error = existing.failure { throw error }
            return existing
        }
        guard let key = try ElevenKey.read() else { throw ReaderError("Najpierw wpisz i zapisz klucz ElevenLabs w Ustawieniach.") }
        let request = try ElevenNetwork.shared.speech(text: book.parts[position], voice: book.voice, key: key)
        let item = ElevenTransfer(destination: url)
        transfers[url.lastPathComponent] = item
        try item.start(request)
        return item
    }
    private func playCurrent() throws {
        preparing?()
        let stream = try ElevenAudio(offset: offset, preferences: settings)
        audio = stream
        stream.onStart = { [weak self] in self?.began() }
        stream.onEnd = { [weak self] in self?.advance() }
        let url = address(index)
        if FileManager.default.fileExists(atPath: url.path) {
            do { try ElevenTransfer.read(url, into: stream.feed); try stream.endOfInput() }
            catch {
                try? FileManager.default.removeItem(at: url)
                throw ReaderError("Nie udało się odczytać zapisanego nagrania. Wznów, aby pobrać je ponownie.")
            }
        } else {
            let item = try transfer(index)
            try item.attach(stream.feed)
            item.onFinish = { [weak self, weak stream] error in
                guard let self, let stream, self.audio === stream else { return }
                if let error { fail(error); return }
                do { try stream.endOfInput() } catch { fail(error) }
            }
        }
    }
    private func began() {
        started?()
        let next = index + 1
        guard book.parts.indices.contains(next), !FileManager.default.fileExists(atPath: address(next).path) else { return }
        // Błąd przedpobrania nie ucina bieżącego fragmentu i nie wywołuje ponowienia.
        do { _ = try transfer(next) } catch {
            let url = address(next)
            let item = transfers[url.lastPathComponent] ?? ElevenTransfer(destination: url)
            item.failure = error
            transfers[url.lastPathComponent] = item
        }
    }
    private func advance() {
        guard !stopped else { return }
        transfers.removeValue(forKey: address(index).lastPathComponent)?.cancel()
        audio?.close()
        audio = nil
        index += 1
        offset = 0
        if book.parts.indices.contains(index) {
            do {
                if remember { try book.save(index: index, seconds: 0) }
                try playCurrent()
            } catch { fail(error) }
        } else {
            do { try stop(keep: false); finished?(nil) } catch { fail(error) }
        }
    }
    func pause() { audio?.pause(); checkpoint() }
    func resume() throws { try audio?.resume() }
    private func fail(_ error: Error) {
        guard !stopped else { finished?(error); return }
        try? stop(keep: true)
        finished?(error)
    }
    func stop(keep: Bool) throws {
        guard !stopped else { return }
        stopped = true
        timer?.invalidate()
        defer {
            audio?.close()
            audio = nil
            transfers.values.forEach { $0.cancel() }
            transfers.removeAll()
        }
        if remember {
            if keep, book.parts.indices.contains(index) { try book.save(index: index, seconds: audio?.position ?? offset) }
            else { try ElevenBookmark.clear() }
        }
    }
}
