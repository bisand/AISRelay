using System.Collections.Generic;
using CommandLine;

public class Options
{
    [Option('r', "read", Required = true, HelpText = "Input files to be processed.")]
    public IEnumerable<string> InputFiles { get; set; }

    // Omitting long name, default --verbose
    [Option(HelpText = "Prints all messages to standard output.")]
    public bool Verbose { get; set; }

    [Value(0, Default = 12)]
    public long Offset { get; set; }
}
