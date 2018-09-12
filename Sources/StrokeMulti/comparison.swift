//
//  comparison.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/11/18.
//

import Foundation
import StrokeModel

struct Row {
    let point: MapPoint
    let patient: Patient
    var results: MultiRunResults? = nil

    init(point: MapPoint, patient: Patient) {
        self.point = point
        self.patient = patient
    }

    var output: String? {
        guard let cbc = results?.countsByCenter else { return nil }
        var out = "\(point.latitude),\(point.longitude),\(patient.id),\(patient.usesHospitalPerformance),"
        let numPrimaries = patient.hospitals.primaries.compactMap({$0.time}).count
        out += "\(numPrimaries),\(patient.core.sex),\(patient.core.age),\(patient.core.timeSinceSymptoms),"
        out += "\(patient.core.race),"
        let countStrings = patient.hospitals.allCenters.map { center in String(cbc[center] ?? 0) }
        out += countStrings.joined(separator: ",")
        return out + "\n"
    }

    mutating func runModel(simulationCount: Int, fixPerformance: Bool = false) {
        patient.setTimes(forPoint: point)
        let model = StrokeModel(patient.inputs)
        results = model.runWithVariance(fixPerformance: fixPerformance, simulationCount: simulationCount)
    }
}
