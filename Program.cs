using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using CommandLine.Text;

namespace AISRelay
{
    class Program
    {
        static void Main(string[] args)
        {
            var result = CommandLine.Parser.Default.ParseArguments<Options>(args);
            // if (!result.Errors.Any())
            // {
            //     // Values are available here
            //     if (result.Value.Verbose) Console.WriteLine("Filenames: {0}", string.Join(",", result.Value.InputFiles.ToArray()));
            // }
            Console.WriteLine("AIS Relay v0.1");
            Console.WriteLine("Listening for AIS messages on UDP port 10110");
            Console.WriteLine("Publishing to MarineTraffic: 5.9.207.224:11089");
            Console.WriteLine("Publishing to OpenCPN: 0.0.0.0:2947");

            bool done = false;
            int listenPort = 10110;
            int publishPort = 2947;
            var localListenerEndpoint = new IPEndPoint(IPAddress.Any, listenPort);
            var localPublisherEndpoint = new IPEndPoint(IPAddress.Broadcast, publishPort);
            var marineTrafficEndpoint = new IPEndPoint(IPAddress.Parse("5.9.207.224"), 11089);
            using UdpClient localListener = new UdpClient(localListenerEndpoint);
            while (!done)
            {
                try
                {
                    byte[] receivedData = localListener.Receive(ref localListenerEndpoint);
                    using (var marineTrafficClient = new UdpClient())
                        marineTrafficClient.BeginSend(receivedData, receivedData.Length, marineTrafficEndpoint, UdpClientSendCallback, marineTrafficClient);
                    using (var localPublisherClient = new UdpClient())
                    {
                        localPublisherClient.EnableBroadcast = true;
                        localPublisherClient.BeginSend(receivedData, receivedData.Length, localPublisherEndpoint, UdpClientSendCallback, localPublisherClient);
                    }
                    Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [DEBUG] {1}", DateTime.Now, Encoding.ASCII.GetString(receivedData).TrimEnd('\n'));
                }
                catch (System.Exception ex)
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
