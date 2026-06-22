import Foundation

final class Ward {
    let records: Records
    let lead: Lead
    let telemeter: Telemeter
    let pager: Pager

    init(records: Records, lead: Lead, telemeter: Telemeter, pager: Pager) {
        self.records = records
        self.lead = lead
        self.telemeter = telemeter
        self.pager = pager
    }

    static func staffedWard() -> Ward {
        Ward(
            records: WardRecords(),
            lead: SensorLead(),
            telemeter: WardTelemeter(),
            pager: WardPager()
        )
    }
}

@MainActor
final class Admitting {

    static let shared = Admitting()

    private var beds: [String: Any] = [:]

    private init() {}

    func bed<T>(_ instance: T, as type: T.Type) {
        beds[String(describing: type)] = instance
    }

    func admit<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = beds[key] as? T {
            return instance
        }
        let built = intake(type)
        beds[key] = built
        return built
    }

    private func intake<T>(_ type: T.Type) -> T {
        switch String(describing: type) {
        case String(describing: Ward.self):
            return Ward.staffedWard() as! T
        case String(describing: Cardiograph.self):
            return Cardiograph(ward: admit(Ward.self)) as! T
        default:
            fatalError("Admitting: no builder for \(type)")
        }
    }
}
