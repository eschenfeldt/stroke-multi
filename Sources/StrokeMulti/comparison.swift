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
    var numPrimaries: Int? = nil
    var numComprehensives: Int? = nil

    init(point: MapPoint, patient: Patient) {
        self.point = point
        self.patient = patient
    }

    var output: String? {
        guard let cbc = results?.countsByCenter, let numPrimaries = numPrimaries,
              let numComprehensives = numComprehensives else { return nil }
        var out = "\(point.id),\(patient.id),\(patient.usesHospitalPerformance),"
        out += "\(numPrimaries),\(numComprehensives),\(patient.core.sex),\(patient.core.age),"
        out += "\(patient.core.timeSinceSymptoms),\(patient.core.race),"
        let countStrings = patient.hospitals.allCenters.map { center in String(cbc[center] ?? 0) }
        out += countStrings.joined(separator: ",")
        return out + "\n"
    }

    mutating func runModel(simulationCount: Int, fixPerformance: Bool = false, useGCD: Bool = true) {
        patient.setTimes(forPoint: point)
        let model = StrokeModel(patient.inputs)
        numPrimaries = patient.hospitals.primaries.compactMap({$0.time}).count
        numComprehensives = patient.hospitals.comprehensives.compactMap({$0.time}).count
        results = model.runWithVariance(fixPerformance: fixPerformance, simulationCount: simulationCount,
                                        useGCD: useGCD)
    }
}
