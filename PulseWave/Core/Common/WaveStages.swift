import Foundation
import Combine
import AppsFlyerLib

enum StageVerdict {
    case advance
    case settle(WaveOutcome)
    case fault(WaveFault)
}

@MainActor
protocol WaveStage {
    var label: String { get }
    func ride(state: BeaconState, di: FunctionDI) async -> StageVerdict
}

@MainActor
struct PushShortCircuitStage: WaveStage {
    let label = "pushShortCircuit"
    
    func ride(state: BeaconState, di: FunctionDI) async -> StageVerdict {
        guard let pushURL = UserDefaults.standard.string(forKey: BeaconKey.pushURL),
              !pushURL.isEmpty else {
            return .advance
        }
        
        let needsConsent = state.current.consentRipe
        
        state.mutate { snap in
            snap.buoyURL = pushURL
            snap.buoyMode = "Active"
            snap.stillness = false
            snap.anchored = true
        }
        
        let vault = di.vaultProvider()
        vault.stash(state.current.freeze())
        vault.stashBuoy(url: pushURL, mode: "Active")
        vault.markPrimed()
        UserDefaults.standard.removeObject(forKey: BeaconKey.pushURL)
        
        return .settle(needsConsent ? .requestConsent : .openBuoy)
    }
}

@MainActor
struct VoltageProbeStage: WaveStage {
    let label = "voltageProbe"
    
    func ride(state: BeaconState, di: FunctionDI) async -> StageVerdict {
        guard state.current.signalsReady else {
            return .settle(.adrift)
        }
        
        do {
            let verdict = try await di.probeProvider().probe()
            if verdict {
                return .advance
            } else {
                return .fault(.voltageMuffled)
            }
        } catch let fault as WaveFault {
            return .fault(fault)
        } catch {
            return .fault(.voltageMuffled)
        }
    }
}

@MainActor
struct OrganicRefetchStage: WaveStage {
    let label = "organicRefetch"
    
    func ride(state: BeaconState, di: FunctionDI) async -> StageVerdict {
        let snap = state.current
        let needsRefetch = snap.organicCurrent && snap.stillness && !snap.rippleHandled
        
        guard needsRefetch else {
            return .advance
        }
        
        state.mutate { $0.rippleHandled = true }
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !state.current.anchored else {
            return .advance
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await di.fetcherProvider().fetch(deviceID: deviceID)
            
            for (k, v) in state.current.echoes {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            
            state.mutate { $0.signals = mapped }
            di.vaultProvider().stash(state.current.freeze())
        } catch {
        }
        
        return .advance
    }
}

@MainActor
struct BuoyLocationStage: WaveStage {
    let label = "buoyLocation"
    
    func ride(state: BeaconState, di: FunctionDI) async -> StageVerdict {
        guard state.current.signalsReady else {
            return .settle(.adrift)
        }
        
        let seed = state.current.signals.mapValues { $0 as Any }
        
        do {
            let url = try await di.locatorProvider().locate(seed: seed)
            
            let needsConsent = state.current.consentRipe
            
            state.mutate { snap in
                snap.buoyURL = url
                snap.buoyMode = "Active"
                snap.stillness = false
                snap.anchored = true
            }
            
            let vault = di.vaultProvider()
            vault.stash(state.current.freeze())
            vault.stashBuoy(url: url, mode: "Active")
            vault.markPrimed()
            UserDefaults.standard.removeObject(forKey: BeaconKey.pushURL)
            
            return .settle(needsConsent ? .requestConsent : .openBuoy)
        } catch let fault as WaveFault {
            return .fault(fault)
        } catch {
            return .fault(.wireSnapped(attempts: 0))
        }
    }
}

@MainActor
final class WaveCoordinator {
    
    let state: BeaconState
    
    private let outcomeSubject = PassthroughSubject<WaveOutcome, Never>()
    var outcomePublisher: AnyPublisher<WaveOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let di: FunctionDI
    
    private var consentPromise: Promise<Bool>?
    
    init(di: FunctionDI = .production()) {
        self.di = di
        self.state = BeaconState()
    }
    
    func warmUp() {
        let record = di.vaultProvider().thaw()
        state.replace(with: BeaconStateSnapshot.hydrate(from: record))
    }
    
    func ingestSignals(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.mutate { $0.signals = mapped }
        di.vaultProvider().stash(state.current.freeze())
    }
    
    func ingestEchoes(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state.mutate { $0.echoes = mapped }
        di.vaultProvider().stash(state.current.freeze())
    }
    
    func surf() async {
        guard !sequenceCompleted else { return }
        
        let stages: [WaveStage] = [
            PushShortCircuitStage(),
            VoltageProbeStage(),
            OrganicRefetchStage(),
            BuoyLocationStage()
        ]
        
        for stage in stages {
            if sequenceCompleted { return }
            
            let verdict = await stage.ride(state: state, di: di)
            
            switch verdict {
            case .advance:
                continue
                
            case .settle(let outcome):
                if case .adrift = outcome {
                    return
                }
                sequenceCompleted = true
                outcomeSubject.send(outcome)
                return
                
            case .fault(let fault):
                sequenceCompleted = true
                outcomeSubject.send(.driftedToShore)
                return
            }
        }
    }
    
    func acceptConsent(c: @escaping () -> Bool) {
        let priorRipple = state.current.consentRipple
        let priorDamped = state.current.consentDamped
        
        let promise = di.echoProvider().echo()
        self.consentPromise = promise
        
        promise
            .sink { [weak self] granted in
                guard let self = self else { return }
                
                let now = Date()
                
                self.state.mutate { snap in
                    if granted {
                        snap.consentRipple = true
                        snap.consentDamped = false
                        snap.consentTracedAt = now
                    } else {
                        snap.consentRipple = false
                        snap.consentDamped = true
                        snap.consentTracedAt = now
                    }
                }
                
                if granted {
                    self.di.echoProvider().armPushTransmitter()
                }
                
                _ = priorRipple
                _ = priorDamped
                
                self.di.vaultProvider().stash(self.state.current.freeze())
                self.outcomeSubject.send(.openBuoy)
                self.consentPromise = nil
                let _ = c()
            }
            .catch { [weak self] error in
                self?.consentPromise = nil
            }
    }
    
    func deferConsent() {
        let now = Date()
        state.mutate { $0.consentTracedAt = now }
        di.vaultProvider().stash(state.current.freeze())
        outcomeSubject.send(.openBuoy)
    }
    
    func reportTideExpired() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}

