import Foundation
import StrokeModel
import Files
import Progress
import Utility

struct RunSettings {
    let timesFile: String
    let hospitalFile: String
    let fixPerformance: Bool
    let patientCount: Int
    let simulationCount: Int
    let replaceResults: Bool
    let useGCD: Bool

    var outFile: File {
        let root = getRoot()
        let path = root + "output/"
        let timesName = (timesFile.components(separatedBy: "/").last ?? timesFile).removing(suffix: ".csv")
        let hospitalName = (hospitalFile.components(separatedBy: "/").last ?? hospitalFile).removing(suffix: ".csv")
        let name = "times=\(timesName)_hospitals=\(hospitalName)_\(fixPerformance ? "fixed" : "random")_swift"
        do {
            return try FileSystem().createFileIfNeeded(at: path + name + ".csv", contents: Data())
        } catch {
            print("Failed to create output file at \(path + name + ".csv")")
            fatalError(error.localizedDescription)
        }
    }

    var nextPatientNum: Int {
        if self.replaceResults { return 0 }
        guard let currentResults = try? outFile.readAsString(encoding: .utf8) else { return 0 }
        var max = -1
        for row in currentResults.components(separatedBy: "\n") {
            let elements = row.components(separatedBy: ",")
            guard elements.count > 1, let patNum = Int(elements[2]) else { continue }
            if patNum > max { max = patNum }
        }
        return max + 1
    }
}

extension String {
    func removing(suffix: String) -> String {
        if self.hasSuffix(suffix) {
            return String(self.prefix(self.count - suffix.count))
        } else { return self }
    }
}

func getRoot() -> String {
    return Folder.current.path + "/"
}

func runModel(_ settings: RunSettings) {

    guard let hospitals = getHospitals(hospitalFile: settings.hospitalFile) else {
        return
    }
    guard let defaultHospitals = getHospitals(hospitalFile: settings.hospitalFile, useDefaultTimes: true) else {
        return
    }
    print("Found \(hospitals.comprehensives.count) comprehensive hospitals" +
          " and \(hospitals.primaries.count) primary hospitals")

    guard let times = getTimes(timesFile: settings.timesFile) else { return }

    print("Found \(times.count) map points")

    var patients: [Patient] = []
    let idOffset = settings.nextPatientNum
    for index in 0..<settings.patientCount {
        let id = index + idOffset
        let patient = Patient(id: id, hospitals: hospitals)
        let defPatient = patient.copy(hospitals: defaultHospitals)
        patients.append(contentsOf: [patient, defPatient])
    }

    do {
        let newFile = try settings.outFile.readAsString().isEmpty
        if settings.replaceResults || newFile {
            try settings.outFile.write(string: hospitals.header)
        }
    } catch {
        print("Couldn't write to \(settings.outFile)")
        print(hospitals.header)
    }
    let t = Date()
    for patient in Progress(patients) {
        var rows: [Row] = []
        for point in times {
            var row = Row(point: point, patient: patient)
            row.runModel(simulationCount: settings.simulationCount, fixPerformance: settings.fixPerformance,
                         useGCD: settings.useGCD)
            rows.append(row)
        }
        let manyRows = rows.compactMap({$0.output}).joined()
        do {
            try settings.outFile.append(string: manyRows)
        } catch {
            print(manyRows)
        }
    }
    let elapsedTime = Date().timeIntervalSince(t).stringFormatted()
    let runCount = (times.count * patients.count * 2)
    let simCount = (runCount * settings.simulationCount).countFormatted()
    print("Completed \(runCount.countFormatted()) model runs (\(simCount) simulations) in \(elapsedTime)")
}

extension TimeInterval {
    func stringFormatted() -> String {
        var miliseconds = (self * 10).rounded()
        miliseconds = miliseconds.truncatingRemainder(dividingBy: 10)
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / (60 * 60)) % 60
        return String(format: "%02d:%02d:%02d.%.f", hours, minutes, seconds, miliseconds)
    }
}

extension Int {
    func countFormatted() -> String {
        if self < 10_000 {
            return "\(self)"
        }
        var divisor = 1_000
        let suffix: String
        if self <= 1_000_000 {
            divisor = 1_000
            suffix = " thousand"
        } else if self <= 1_000_000_000 {
            divisor = 1_000_000
            suffix = " million"
        } else {
            divisor = 1_000_000_000
            suffix = " billion"
        }
        let rem = self % divisor
        let val: String
        if rem == 0 {
            val = "\(self / divisor)"
        } else {
            val = "\(Double(self) / Double(divisor))"
        }
        return "\(val)\(suffix)"
    }
}
