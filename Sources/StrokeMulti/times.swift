//
//  times.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/11/18.
//

import Foundation
import Files

struct MapPoint {
    let latitude: Double
    let longitude: Double
    let times: [Int: Double?]
}

func getTimes(timesFile: String, useWorkingDirectory: Bool = false) -> [MapPoint]? {
    let path = getRoot(useWorkingDirectory: useWorkingDirectory)
    let fileName = timesFile.suffix(4) == ".csv" ? timesFile : timesFile + ".csv"
    let filePath = URL(fileURLWithPath: path + fileName)
    var allRows: [String] = []
    do {
        allRows = try String(contentsOf: filePath, encoding: .utf8).components(separatedBy: "\n")
    } catch {
        print("Couldn't read file \(timesFile)")
        return nil
    }

    var points: [MapPoint] = []
    let header = allRows[0].components(separatedBy: "|")
    let centerIDStrings = header.suffix(header.count - 2)
    let centerIDs: [Int] = centerIDStrings.map{ colName in
        if let centerID = Int(colName) {
            return centerID
        } else {
            print("Malformed times file \(timesFile) with header \(header)")
            print("Couldn't convert \"\(colName)\" to an integer")
            return -1
        }
    }
    for row in allRows {
        let elements = row.components(separatedBy: "|")
        if elements.count == 1 || elements[0] == "Latitude" { continue }
        guard let latitude = Double(elements[0]) else {
            print("Couldn't read latitude on \(row)")
            continue
        }
        guard let longitude = Double(elements[1]) else {
            print("Couldn't read longitude on \(row)")
            continue
        }
        var times: [Int: Double?] = [:]
        for (col, time) in elements.suffix(elements.count - 2).enumerated() {
            let centerID = centerIDs[col]
            times[centerID] = Double(time)
        }
        points.append(MapPoint(latitude: latitude, longitude: longitude, times: times))
    }
    return points
}
