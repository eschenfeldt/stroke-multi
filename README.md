# StrokeMulti

Command line tool to run [a stroke triage model](https://github.com/eschenfeldt/stroke-swift) on randomly generated patients at a set of provided locations. Locations and adjacent hospitals must be provided, with appropriate pre-calculated travel times.  Runs model using both generic hospital performance characteristics and provided specific characteristics for each hospital to allow analysis of the impact of including hospital performance in the model.

**Included demo input and results files use random hospital performance characteristics and do not reflect the performance of any real hospitals.**

### Usage

Build the tool by calling `swift build` in the project root. This creates an executable `StrokeMulti`. Use it as

``` 
StrokeMulti <hospital_file> <times_file> <options> 
```

where `<hospital_file>` and `<times_file>` are paths to correctly formatted hospital and location files relative to the current working directory. Use `StrokeMulti --help` for more information on options.
