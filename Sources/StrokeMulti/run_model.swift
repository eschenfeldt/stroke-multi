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
    let useWorkingDirectory: Bool

    var outFile: File {
        let root = getRoot(useWorkingDirectory: self.useWorkingDirectory)
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

func getRoot(useWorkingDirectory: Bool) -> String {
    let path = "\(Folder.home.path)Dropbox (Partners Healthcare)/Stroke/StrokeMulti/"
    let here = Folder.current.path
    return useWorkingDirectory ? here + "/" : path
}

func runModel(_ settings: RunSettings) {

    guard let hospitals = getHospitals(hospitalFile: settings.hospitalFile,
                                       useWorkingDirectory: settings.useWorkingDirectory) else {
        return
    }
    guard let defaultHospitals = getHospitals(hospitalFile: settings.hospitalFile, useDefaultTimes: true,
                                              useWorkingDirectory: settings.useWorkingDirectory) else {
        return
    }
    print("Found \(hospitals.comprehensives.count) comprehensive hospitals" +
          " and \(hospitals.primaries.count) primary hospitals")

    guard let times = getTimes(timesFile: settings.timesFile,
                               useWorkingDirectory: settings.useWorkingDirectory) else { return }

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
            row.runModel(simulationCount: settings.simulationCount, fixPerformance: settings.fixPerformance)
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
    let runCount = times.count * patients.count * 2
    let simCountThousands = (runCount * settings.simulationCount) / 1000
    print("Completed \(runCount) model runs (\(simCountThousands)K simulations) in \(elapsedTime)")
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
