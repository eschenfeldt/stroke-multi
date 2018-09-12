//
//  patient.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/11/18.
//

import Foundation
import StrokeModel

struct Patient {

    struct Core {
        let sex: Sex
        let age: Int
        let race: Double
        let timeSinceSymptoms: Double

        init(sex: Sex? = nil, age: Int? = nil, race: Double? = nil, timeSinceSymptoms: Double? = nil) {
            self.sex = sex ?? Sex(rawValue: Int.random(in: 0...1))!
            self.age = age ?? Int.random(in: 30...85)
            self.race = race ?? Double(Int.random(in: 0...9))
            self.timeSinceSymptoms = timeSinceSymptoms ?? Double.random(in: 10...100)
        }

    }

    let id: Int
    let core: Core
    let hospitals: Hospitals
    var usesHospitalPerformance: Bool {
        return hospitals.usesHospitalPerformance
    }
    var inputs: Inputs {
        guard let mi = Inputs(sex: core.sex, age: core.age, race: core.race, timeSinceSymptoms: core.timeSinceSymptoms, primaries: hospitals.primaries, comprehensives: hospitals.comprehensives) else {
            fatalError("Malformed hospitals")
        }
        return mi
    }

    init(id: Int, hospitals: Hospitals, core: Core? = nil) {
        self.id = id
        self.core = core ?? Core()
        self.hospitals = hospitals
    }

    func copy(hospitals: Hospitals) -> Patient {
        return Patient(id: self.id, hospitals: hospitals, core: self.core)
    }

    func setTimes(forPoint point: MapPoint) {
        for center in hospitals.comprehensives + hospitals.primaries {
            if let centerID = center.centerID {
                center.time = point.times[centerID] ?? nil
            }
        }
    }
}
