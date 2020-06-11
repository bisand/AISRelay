using System.Collections.Generic;
using CommandLine;

public class Options
{
    [Option('d', "debug", Required = false, Default = false, HelpText = "Debug log to console.")]
    public bool Debug { get; set; }

    [Option('l', "listen", Required = false, Default = 10110, HelpText = "Listen port for incoming UDP messages")]
    public int ListenUdpPort { get; set; }

    [Option('b', "broadcast", Required = false, Default = 2947, HelpText = "Broadcast port for outgoing UDP messages")]
    public int BroadcastPort { get; set; }

    [Option('a', "mt-host", Required = false, Default = "", HelpText = "Host for outgoing UDP messages to MarineTraffic.com")]
    public string MarineTrafficHost { get; set; }

    [Option('p', "mt-port", Required = false, Default = 0, HelpText = "Port for outgoing UDP messages to MarineTraffic.com")]
    public int MarineTrafficPort { get; set; }


}
