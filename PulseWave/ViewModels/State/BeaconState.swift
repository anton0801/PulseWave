import Foundation
import Combine


@MainActor
final class BeaconState {
    
    let subject: CurrentValueSubject<BeaconStateSnapshot, Never>
    
    init(initial: BeaconStateSnapshot = BeaconStateSnapshot()) {
        self.subject = CurrentValueSubject(initial)
    }
    
    var current: BeaconStateSnapshot {
        get { subject.value }
    }
    
    /// Mutation через closure — closure получает inout копию, после применения push новый snapshot
    func mutate(_ block: (inout BeaconStateSnapshot) -> Void) {
        var copy = subject.value
        block(&copy)
        subject.send(copy)
    }
    
    func replace(with snapshot: BeaconStateSnapshot) {
        subject.send(snapshot)
    }
}
