//
//  main.swift
//  StrokeMulti
//
//  Created by Patrick Eschenfeldt (ITA) on 9/12/18.
//

import Foundation
import Utility

let defPC = 10
let defSim = 1000
#if os(Linux)
let defUseGCD = false
#else
let defUseGCD = true
#endif

let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let overview = ("Run the stroke triage model for a number of randomly generated patients at the given points, " +
                "using given hospitals and travel times. Saves results to a CSV file.")

let parser = ArgumentParser(usage: "<hospital_file> <times_file> <options>", overview: overview)
let hospitalFileArg: PositionalArgument<String> = parser.add(
    positional: "hospital_file", kind: String.self,
    usage: "Relative path to file describing hospitals to consider"
)
let timesFileArg: PositionalArgument<String> = parser.add(
    positional: "times_file", kind: String.self,
    usage: "Relative path to file with map points and travel time from points to hospitals"
)
let patientCountArg: OptionArgument<Int> = parser.add(
    option: "--patient_count", shortName: "-p", kind: Int.self,
    usage: "Number of random patients to generate. Each patient is tested at every map point. Default \(defPC)"
)
let simulationCountArg: OptionArgument<Int> = parser.add(
    option: "--simulation_count", shortName: "-s", kind: Int.self,
    usage: "Number of simulations used for each model run. Default \(defSim)"
)
let fixPerformanceArg: OptionArgument<Bool> = parser.add(
    option: "--fix_performance", kind: Bool.self,
    usage: "Fix the performance level across hospitals, so comparisons use only distribution"
)
let replaceResultsArg: OptionArgument<Bool> = parser.add(
    option: "--replace_results", kind: Bool.self,
    usage: "Overwrite any existing results (for this set of hospitals and points)"
)
let useGCDArg: OptionArgument<Bool> = parser.add(
    option: "--grand_central", kind: Bool.self,
    usage: "Use Grand Central Dispatch to parallelize simulations (Default \(defUseGCD))"
)

func processArguments(_ arguments: ArgumentParser.Result) -> RunSettings? {
    guard let hospitalFile = arguments.get(hospitalFileArg) else {
        print("No hospital file name found")
        return nil
    }
    guard let timesFile = arguments.get(timesFileArg) else {
        print("No times name file found")
        return nil
    }
    let patientCount = arguments.get(patientCountArg) ?? defPC
    let simulationCount = arguments.get(simulationCountArg) ?? defSim
    let fixPerformance = arguments.get(fixPerformanceArg) ?? false
    let replaceResults = arguments.get(replaceResultsArg) ?? false
    let useGCD = arguments.get(useGCDArg) ?? defUseGCD

    return RunSettings(timesFile: timesFile, hospitalFile: hospitalFile, fixPerformance: fixPerformance,
                       patientCount: patientCount, simulationCount: simulationCount, replaceResults: replaceResults,
                       useGCD: useGCD)
}

do {
    let parsedArguments = try parser.parse(arguments)
    if let runSettings = processArguments(parsedArguments) {
        runModel(runSettings)
    }
} catch let error as ArgumentParserError {
    print(error.description)
} catch let error{
    print(error.localizedDescription)
}
