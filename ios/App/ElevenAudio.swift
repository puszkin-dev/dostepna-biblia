import AVFoundation
import AudioToolbox

/// Parser dostaje kolejne porcje tego samego MP3; dekoder zachowuje stan między pakietami.
final class ElevenAudio {
    private let engine: AVAudioEngine
    private let player = AVAudioPlayerNode()
    private let pitch = AVAudioUnitTimePitch()
    private var parser: AudioFileStreamID?
    private var decoder: AVAudioConverter?
    private var compressed: AVAudioFormat?
    private var pcm: AVAudioFormat?
    private var pending = 0
    private var ended = false
    private var started = false
    private var closed = false
    private var failure: Error?
    private var decodedFrames: Int64 = 0
    private var pausedPosition: Double?
    private let resumeTime: Double
    private var skipFrames: Int64 = 0
    private let preferences: SpeechPreferences
    var onStart: (() -> Void)?
    var onEnd: (() -> Void)?

    init(offset: Double, preferences: SpeechPreferences, engine: AVAudioEngine = AVAudioEngine()) throws {
        self.engine = engine
        resumeTime = max(0, offset)
        self.preferences = preferences
        let status = AudioFileStreamOpen(Unmanaged.passUnretained(self).toOpaque(), { _, _, _, _ in }, {
            context, bytes, packets, pointer, descriptions in
            let audio = Unmanaged<ElevenAudio>.fromOpaque(context).takeUnretainedValue()
            do { try audio.receive(bytes, packets, pointer, descriptions) } catch { audio.failure = error }
        }, kAudioFileMP3Type, &parser)
        guard status == noErr else { throw Self.invalid }
    }
    private static var invalid: ReaderError { ReaderError("Nie można odtworzyć strumienia MP3 ElevenLabs.") }

    func feed(_ bytes: Data) throws {
        guard let parser, !closed else { return }
        let result = bytes.withUnsafeBytes {
            AudioFileStreamParseBytes(parser, UInt32($0.count), $0.baseAddress, [])
        }
        if let failure { throw failure }
        guard result == noErr else { throw Self.invalid }
    }

    private func setup() throws {
        guard let parser else { throw Self.invalid }
        var description = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout.size(ofValue: description))
        guard AudioFileStreamGetProperty(parser, kAudioFileStreamProperty_DataFormat, &size, &description) == noErr,
              let source = AVAudioFormat(streamDescription: &description),
              let target = AVAudioFormat(standardFormatWithSampleRate: source.sampleRate, channels: source.channelCount),
              let converter = AVAudioConverter(from: source, to: target) else { throw Self.invalid }
        compressed = source
        pcm = target
        decoder = converter
        skipFrames = Int64(resumeTime * target.sampleRate)
        engine.attach(player)
        engine.attach(pitch)
        pitch.rate = Float(pow(2.0, Double(preferences.speed - 50) / 50.0))
        player.volume = Float(preferences.volume) / 100
        engine.connect(player, to: pitch, format: target)
        engine.connect(pitch, to: engine.mainMixerNode, format: target)
        do { try engine.start() } catch { throw Self.invalid }
    }

    private func receive(_ bytes: UInt32, _ packets: UInt32, _ pointer: UnsafeRawPointer,
                         _ descriptions: UnsafeMutablePointer<AudioStreamPacketDescription>?) throws {
        guard !closed, failure == nil, bytes > 0, packets > 0 else { return }
        if decoder == nil { try setup() }
        guard let compressed else { throw Self.invalid }
        let sizes = descriptions.map { UnsafeBufferPointer(start: $0, count: Int(packets)) }
        let largest = sizes?.map(\.mDataByteSize).max() ?? ((bytes + packets - 1) / packets)
        guard largest > 0 else { throw Self.invalid }
        let input = AVAudioCompressedBuffer(format: compressed, packetCapacity: packets, maximumPacketSize: Int(largest))
        guard bytes <= input.byteCapacity else { throw Self.invalid }
        input.data.copyMemory(from: pointer, byteCount: Int(bytes))
        if let sizes, let destination = input.packetDescriptions, let source = sizes.baseAddress {
            destination.update(from: source, count: sizes.count)
        }
        input.byteLength = bytes
        input.packetCount = packets
        try convert(input)
    }

    private func convert(_ input: AVAudioCompressedBuffer?) throws {
        guard let decoder, let pcm else { throw Self.invalid }
        var offered = false
        while true {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: pcm, frameCapacity: 4096) else { throw Self.invalid }
            var error: NSError?
            let status = decoder.convert(to: buffer, error: &error) { _, state in
                if let input, !offered {
                    offered = true
                    state.pointee = .haveData
                    return input
                }
                state.pointee = input == nil ? .endOfStream : .noDataNow
                return nil
            }
            guard status != .error else { throw Self.invalid }
            if buffer.frameLength > 0 { schedule(buffer) }
            if status != .haveData || buffer.frameLength == 0 { break }
        }
    }

    private func schedule(_ buffer: AVAudioPCMBuffer) {
        let count = Int64(buffer.frameLength)
        let omitted = min(count, max(0, skipFrames - decodedFrames))
        decodedFrames += count
        guard omitted < count else { return }
        if omitted > 0, let channels = buffer.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                memmove(channels[channel], channels[channel] + Int(omitted), Int(count - omitted) * MemoryLayout<Float>.stride)
            }
            buffer.frameLength = AVAudioFrameCount(count - omitted)
        }
        pending += 1
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, !self.closed else { return }
                self.pending -= 1
                self.completeIfReady()
            }
        }
        if !started {
            started = true
            player.play()
            onStart?()
        }
    }

    func endOfInput() throws {
        guard decoder != nil else { throw Self.invalid }
        try convert(nil)
        guard decodedFrames > 0 else { throw Self.invalid }
        ended = true
        completeIfReady()
    }
    private func completeIfReady() { if ended && pending == 0 && !closed { onEnd?() } }
    var position: Double {
        if let pausedPosition { return pausedPosition }
        guard let render = player.lastRenderTime, let time = player.playerTime(forNodeTime: render),
              time.sampleRate > 0 else { return resumeTime }
        let rendered = resumeTime + max(0, Double(time.sampleTime) / time.sampleRate)
        return min(rendered, Double(decodedFrames) / time.sampleRate)
    }
    func pause() {
        // Po wstrzymaniu węzeł może już nie udostępniać zegara odtwarzania.
        pausedPosition = position
        player.pause()
    }
    func resume() throws {
        if !engine.isRunning { try engine.start() }
        player.play()
        pausedPosition = nil
    }
    func close() {
        guard !closed else { return }
        closed = true
        player.stop()
        engine.stop()
        if let parser { AudioFileStreamClose(parser); self.parser = nil }
    }
    deinit { close() }
}
