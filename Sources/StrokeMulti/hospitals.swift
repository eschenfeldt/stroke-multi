//
//  hospitals.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/11/18.
//

import Foundation
import StrokeModel
import Files

extension StrokeCenter.CenterType {
    var asString: String {
        switch self {
            case .comprehensive: return "CSC"
            case .primary: return "PSC"
        }
    }
}

extension StrokeCenter {
    
    var nameAndType: String {
        return "\(shortName) (\(centerType.asString))"
    }
    
}

struct Hospitals {
    let primaries: [StrokeCenter]
    let comprehensives: [StrokeCenter]
    let usesHospitalPerformance: Bool

    var allCenters: [StrokeCenter] {
        return primaries + comprehensives
    }

    var allCenterLabels: [String] {
        return allCenters.compactMap({$0.nameAndType})
    }

    var headerCols: [Int: Int] {
        let firstHospital = headerStart.components(separatedBy: ",").count
        var out: [Int: Int] = [:]
        var colNum = firstHospital
        for center in allCenters {
            guard let centerID = center.centerID else { continue }
            out[centerID] = colNum
            colNum += 1
        }
        return out
    }

    var headerStart: String {
        return "Location,Patient,Varying Hospitals,PSC Count,CSC Count,Sex,Age,Symptoms,RACE"
    }

    var header: String {
        return headerStart + "," + centerIDStrings.joined(separator: ",") + "\n"
    }
}

func getHospitals(hospitalFile: String, useDefaultTimes: Bool = false) -> Hospitals? {
    let root = getRoot()
    let fileName = hospitalFile.suffix(4) == ".csv" ? hospitalFile : hospitalFile + ".csv"
    let filePath = URL(fileURLWithPath: root + fileName)
    var allRows: [String] = []
    do {
        allRows = try String(contentsOf: filePath, encoding: .utf8).components(separatedBy: .newlines)
    } catch {
        print("Couldn't read file \(hospitalFile)")
        return nil
    }
    var primaries: [Int: StrokeCenter] = [:]
    var destinations: [Int: (id: Int, time: Double)] = [:]
    var comprehensives: [Int: StrokeCenter] = [:]

    for row in allRows {
        let elements = row.components(separatedBy: "|")
        guard elements.count > 1 && elements[0] != "CenterID" else { continue }
        guard let centerID = Int(elements[0]) else {
            print("Failed to scan center ID in \(row)")
            continue
        }
        let centerType: StrokeCenter.CenterType
        switch elements[1] {
        case "Primary":
            centerType = .primary
        case "Comprehensive":
            centerType = .comprehensive
        default:
            print("Failed to scan center type in \(row)")
            continue
        }
        let longName = "Center (\(centerID))"
        let name = "\(centerID)"
        let dtnDist: StrokeCenter.TimeDistribution?
        let dtpDist: StrokeCenter.TimeDistribution?
        if useDefaultTimes {
            dtnDist = nil
            dtpDist = nil
        } else {
            dtnDist = StrokeCenter.TimeDistribution(
                firstQuartile: Double(elements[4])!,
                median: Double(elements[5])!,
                thirdQuartile: Double(elements[6])!
            )
            if centerType == .comprehensive {
                dtpDist = StrokeCenter.TimeDistribution(
                    firstQuartile: Double(elements[7])!,
                    median: Double(elements[8])!,
                    thirdQuartile: Double(elements[9])!
                )
            } else {
                dtpDist = nil
            }
        }
        if let destID = Int(elements[2]) {
            let transferTime = Double(elements[3])!
            destinations[centerID] = (destID, transferTime)
        }
        let center = StrokeCenter(fromFullName: longName, andShortName: name,
                                  ofType: centerType, withCenterID: centerID,
                                  dtnDist: dtnDist, dtpDist: dtpDist)
        switch centerType {
        case .primary: primaries[centerID] = center
        case .comprehensive: comprehensives[centerID] = center
        }
    }

    for (key: sourceID, value: (id: destID, time: transferTime)) in destinations {
        guard let dest = comprehensives[destID] else {
            print("Could not find destination hospital \(destID)")
            continue
        }
        primaries[sourceID]?.addTransferDestination(dest, transferTime: transferTime)
    }

    return Hospitals(primaries: Array(primaries.values),
                     comprehensives: Array(comprehensives.values),
                     usesHospitalPerformance: !useDefaultTimes)
}
