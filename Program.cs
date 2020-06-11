using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using CommandLine;
using CommandLine.Text;

namespace AISRelay
{
    class Program
    {
        private static readonly string version = "0.1.0";
        static void Main(string[] args)
        {
            var parser = new Parser(with => { with.IgnoreUnknownArguments = true; });
            var parserResult = parser.ParseArguments<Options>(args);
            parserResult
                .WithParsed(Run)
                .WithNotParsed(errs => DisplayHelp(parserResult, errs));
        }

        private static void DisplayHelp<T>(ParserResult<T> result, IEnumerable<Error> errs)
        {
            var helpText = HelpText.AutoBuild(result, h =>
            {
                h.AdditionalNewLineAfterOption = false;
                h.Heading = string.Format("AIS Relay {0}", version); //change header
                h.Copyright = "Copyright (c) 2020 André Biseth"; //change copyright text
                return HelpText.DefaultParsingErrorsHandler(result, h);
            }, e => e);
            Console.WriteLine(helpText);
        }

        private static void Run(Options options)
        {
            if (options.ListenUdpPort == options.BroadcastPort)
            {
                Console.WriteLine("Listen port and Broadcast port cannot be the same ({0}). Please change one of them.", options.ListenUdpPort);
                return;
            }
            Console.WriteLine(string.Format("AIS Relay {0}", version));
            Console.WriteLine("Listening for AIS messages on UDP port {0}", options.ListenUdpPort);
            Console.WriteLine("Publishing to MarineTraffic: {0}:{1}", options.MarineTrafficHost, options.MarineTrafficPort);
            Console.WriteLine("Broadcasting UDP messages on port {0}", options.BroadcastPort);

            bool done = false;
            var localListenerEndpoint = new IPEndPoint(IPAddress.Any, options.ListenUdpPort);
            var localPublisherEndpoint = new IPEndPoint(IPAddress.Broadcast, options.BroadcastPort);
            using UdpClient localListener = new UdpClient(localListenerEndpoint);
            while (!done)
            {
                try
                {
                    byte[] receivedData = localListener.Receive(ref localListenerEndpoint);
                    if (!string.IsNullOrWhiteSpace(options.MarineTrafficHost) && options.MarineTrafficPort != 0)
                        using (var marineTrafficClient = new UdpClient())
                            marineTrafficClient.BeginSend(receivedData, receivedData.Length, options.MarineTrafficHost, options.MarineTrafficPort, UdpClientSendCallback, marineTrafficClient);
                    using (var localPublisherClient = new UdpClient())
                    {
                        localPublisherClient.EnableBroadcast = true;
                        localPublisherClient.BeginSend(receivedData, receivedData.Length, localPublisherEndpoint, UdpClientSendCallback, localPublisherClient);
                    }
                    if (options.Debug)
                        Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [DEBUG] {1}", DateTime.Now, Encoding.ASCII.GetString(receivedData).TrimEnd('\n'));
                }
                catch (Exception ex)
                {
                    Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [ERROR] {1}", DateTime.Now, ex);
                }
            }
        }

        private static void UdpClientSendCallback(IAsyncResult ar)
        {
            if (ar != null && ar.AsyncState is UdpClient)
            {
                try
                {
                    (ar.AsyncState as UdpClient).EndSend(ar);
                    (ar.AsyncState as UdpClient).Close();
                }
                catch (System.Exception ex)
                {
                    Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [ERROR] {1}", DateTime.Now, ex);
                }
            }
        }
    }
}
