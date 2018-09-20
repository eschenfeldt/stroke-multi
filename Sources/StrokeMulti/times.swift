//
//  times.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/11/18.
//

import Foundation
import Files

struct MapPoint {
    let id: Int
    let times: [Int: Double?]
}

func getTimes(timesFile: String) -> [MapPoint]? {
    let path = getRoot()
    let fileName = timesFile.suffix(4) == ".csv" ? timesFile : timesFile + ".csv"
    let filePath = URL(fileURLWithPath: path + fileName)
    var allRows: [String] = []
    do {
        allRows = try String(contentsOf: filePath, encoding: .utf8).components(separatedBy: .newlines)
    } catch {
        print("Couldn't read file \(timesFile)")
        return nil
    }

    var points: [MapPoint] = []
    let header = allRows[0].components(separatedBy: "|")
    let centerIDStrings = header.suffix(header.count - 1)
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
        if elements.count == 1 || elements[0] == "ID" { continue }
        guard let id = Int(elements[0]) else {
            print("Couldn't read latitude on \(row)")
            continue
        }
        var times: [Int: Double?] = [:]
        for (col, time) in elements.suffix(elements.count - 1).enumerated() {
            let centerID = centerIDs[col]
            times[centerID] = Double(time)
        }
        points.append(MapPoint(id: id, times: times))
    }
    return points
}
