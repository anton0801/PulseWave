import AVFoundation
import Accelerate

// MARK: - Audio Engine
// Generates all sounds procedurally via AVAudioEngine — no audio files required.
// Supports: binaural beats, white noise, brown noise, pink noise, sine tones, rain, drone.

final class PulseAudioEngine: ObservableObject {

    // MARK: - Published
    @Published var isPlaying: Bool = false
    @Published var currentSoundType: SoundType = .binaural
    @Published var volume: Float = 0.7

    // MARK: - Engine
    private let engine = AVAudioEngine()
    private var nodes: [AVAudioNode] = []

    // Binaural
    private var leftToneNode: AVAudioSourceNode?
    private var rightToneNode: AVAudioSourceNode?

    // Noise
    private var noiseNode: AVAudioSourceNode?

    // Mixer per sound type
    private let mainMixer = AVAudioMixerNode()

    // MARK: - Tone state (thread-safe via atomic-style)
    private var leftPhase: Double = 0
    private var rightPhase: Double = 0
    private var noiseState: UInt64 = 12345
    private var brownAccum: Float = 0

    // Frequencies
    private var baseFreq: Double = 200        // carrier
    private var beatFreq: Double = 10         // binaural beat (Hz diff between ears)

    // MARK: - Init
    init() {
        setupSession()
    }

    deinit {
        stop()
    }

    // MARK: - Session
    private func setupSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Public API

    func play(soundType: SoundType) {
        stop()
        currentSoundType = soundType
        configureFor(soundType: soundType)
        do {
            try engine.start()
            isPlaying = true
            fadeIn()
        } catch {
            print("Engine start error: \(error)")
        }
    }

    func stop() {
        guard isPlaying || engine.isRunning else {
            cleanupNodes()
            return
        }
        fadeOut {
            self.engine.stop()
            self.cleanupNodes()
            DispatchQueue.main.async { self.isPlaying = false }
        }
    }

    func setVolume(_ v: Float) {
        volume = v
        mainMixer.outputVolume = v
    }

    // MARK: - Configure by SoundType

    private func configureFor(soundType: SoundType) {
        engine.attach(mainMixer)
        engine.connect(mainMixer, to: engine.mainMixerNode, format: nil)
        mainMixer.outputVolume = 0 // start silent, fade in

        switch soundType {
        case .binaural:
            baseFreq = 200; beatFreq = 10
            addBinauralNodes()
        case .whitenoise:
            addNoiseNode(type: .white)
        case .nature:
            // Brown noise + slow LFO modulation simulates rain
            addNoiseNode(type: .brown)
            addLFOModulatedTone(freq: 80, modDepth: 40, modRate: 0.3)
        case .focus:
            baseFreq = 140; beatFreq = 14   // beta waves — focus
            addBinauralNodes()
            addNoiseNode(type: .pink, gain: 0.18)
        case .meditation:
            baseFreq = 256; beatFreq = 6    // theta waves — meditation
            addBinauralNodes()
            addDroneTone(freq: 128, gain: 0.12)
        case .sleep:
            baseFreq = 180; beatFreq = 2    // delta waves — sleep
            addBinauralNodes()
            addNoiseNode(type: .brown, gain: 0.15)
        case .lofi:
            baseFreq = 220; beatFreq = 8
            addBinauralNodes()
            addNoiseNode(type: .pink, gain: 0.12)
        case .ambient:
            baseFreq = 180; beatFreq = 4
            addBinauralNodes()
            addDroneTone(freq: 90, gain: 0.15)
        case .classical:
            baseFreq = 256; beatFreq = 5
            addBinauralNodes()
            addDroneTone(freq: 128, gain: 0.10)
        }
    }

    // MARK: - Binaural Nodes

    private func addBinauralNodes() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let sampleRate = 44100.0

        // Reset phases
        leftPhase = 0
        rightPhase = 0

        let leftFreq = baseFreq
        let rightFreq = baseFreq + beatFreq

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftStep = leftFreq / sampleRate
            let rightStep = rightFreq / sampleRate

            // Non-interleaved: buffer 0 = left channel, buffer 1 = right channel
            let leftBuf  = ablPointer.count > 0 ? UnsafeMutableBufferPointer<Float>(ablPointer[0]) : nil
            let rightBuf = ablPointer.count > 1 ? UnsafeMutableBufferPointer<Float>(ablPointer[1]) : leftBuf

            for frame in 0..<Int(frameCount) {
                let leftSample  = Float(sin(2.0 * .pi * self.leftPhase))  * 0.35
                let rightSample = Float(sin(2.0 * .pi * self.rightPhase)) * 0.35

                self.leftPhase  += leftStep
                self.rightPhase += rightStep
                if self.leftPhase  >= 1.0 { self.leftPhase  -= 1.0 }
                if self.rightPhase >= 1.0 { self.rightPhase -= 1.0 }

                leftBuf?[frame]  = leftSample
                rightBuf?[frame] = rightSample
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)
        nodes.append(sourceNode)
        leftToneNode = sourceNode
    }

    // MARK: - Noise Node

    enum NoiseType { case white, pink, brown }

    private func addNoiseNode(type: NoiseType, gain: Float = 0.4) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        noiseState = UInt64(Date().timeIntervalSince1970 * 1000)
        brownAccum = 0

        // Pink noise b values
        var b0: Float = 0; var b1: Float = 0; var b2: Float = 0
        var b3: Float = 0; var b4: Float = 0; var b5: Float = 0; var b6: Float = 0

        let noiseNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let sample: Float

                switch type {
                case .white:
                    sample = self.whiteNoise() * gain

                case .brown:
                    let white = self.whiteNoise()
                    self.brownAccum = (self.brownAccum + 0.02 * white) / 1.02
                    sample = self.brownAccum * 3.5 * gain

                case .pink:
                    let white = self.whiteNoise()
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    b6 = white * 0.5362
                    let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.115926) * 0.11
                    sample = pink * gain
                }

                for i in 0..<ablPointer.count {
                    let buf = UnsafeMutableBufferPointer<Float>(ablPointer[i])
                    if frame < buf.count { buf[frame] = sample }
                }
            }
            return noErr
        }

        engine.attach(noiseNode)
        engine.connect(noiseNode, to: mainMixer, format: format)
        nodes.append(noiseNode)
    }

    // MARK: - Drone Tone (ambient pad)

    private func addDroneTone(freq: Double, gain: Float = 0.2) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let sampleRate = 44100.0
        var phase: Double = 0
        var phase2: Double = 0  // 5th harmonic

        let droneNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let step = freq / sampleRate
            let step2 = (freq * 1.5) / sampleRate

            for frame in 0..<Int(frameCount) {
                let s1 = Float(sin(2.0 * .pi * phase)) * 0.6
                let s2 = Float(sin(2.0 * .pi * phase2)) * 0.3
                let sample = (s1 + s2) * gain

                phase += step
                phase2 += step2
                if phase >= 1.0 { phase -= 1.0 }
                if phase2 >= 1.0 { phase2 -= 1.0 }

                for i in 0..<ablPointer.count {
                    let buf = UnsafeMutableBufferPointer<Float>(ablPointer[i])
                    if frame < buf.count { buf[frame] = sample }
                }
            }
            return noErr
        }

        engine.attach(droneNode)
        engine.connect(droneNode, to: mainMixer, format: format)
        nodes.append(droneNode)
    }

    // MARK: - LFO Modulated Tone (rain-like)

    private func addLFOModulatedTone(freq: Double, modDepth: Double, modRate: Double) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let sampleRate = 44100.0
        var phase: Double = 0
        var lfoPhase: Double = 0

        let lfoNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let lfoStep = modRate / sampleRate

            for frame in 0..<Int(frameCount) {
                let modFreq = freq + modDepth * sin(2.0 * .pi * lfoPhase)
                let step = modFreq / sampleRate
                let sample = Float(sin(2.0 * .pi * phase)) * 0.12

                phase += step
                lfoPhase += lfoStep
                if phase >= 1.0 { phase -= 1.0 }
                if lfoPhase >= 1.0 { lfoPhase -= 1.0 }

                for i in 0..<ablPointer.count {
                    let buf = UnsafeMutableBufferPointer<Float>(ablPointer[i])
                    if frame < buf.count { buf[frame] = sample }
                }
            }
            return noErr
        }

        engine.attach(lfoNode)
        engine.connect(lfoNode, to: mainMixer, format: format)
        nodes.append(lfoNode)
    }

    // MARK: - Noise Util

    private func whiteNoise() -> Float {
        noiseState = noiseState &* 6364136223846793005 &+ 1442695040888963407
        let bits = UInt32(noiseState >> 33)
        return (Float(bits) / Float(UInt32.max)) * 2.0 - 1.0
    }

    // MARK: - Fade In / Out

    private func fadeIn() {
        let steps = 30
        let interval = 0.04
        var step = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            step += 1
            let v = Float(step) / Float(steps) * self.volume
            self.mainMixer.outputVolume = min(v, self.volume)
            if step >= steps { timer.invalidate() }
        }
    }

    private func fadeOut(completion: @escaping () -> Void) {
        let steps = 20
        let interval = 0.03
        var step = 0
        let startVol = mainMixer.outputVolume
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); completion(); return }
            step += 1
            let v = startVol * (1.0 - Float(step) / Float(steps))
            self.mainMixer.outputVolume = max(v, 0)
            if step >= steps {
                timer.invalidate()
                completion()
            }
        }
    }

    // MARK: - Cleanup

    private func cleanupNodes() {
        for node in nodes {
            if engine.attachedNodes.contains(node) {
                engine.detach(node)
            }
        }
        nodes.removeAll()
        leftToneNode = nil
        rightToneNode = nil
        noiseNode = nil

        if engine.attachedNodes.contains(mainMixer) {
            engine.detach(mainMixer)
        }
    }
}
