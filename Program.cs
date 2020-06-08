using System;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace AISRelay
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("AIS Relay v0.1");
            Console.WriteLine("Listening for AIS messages on UDP port 10110");
            Console.WriteLine("Publishing to MarineTraffic: 5.9.207.224:11089");
            Console.WriteLine("Publishing to OpenCPN: 0.0.0.0:2947");

            bool done = false;
            int listenPort = 10110;
            int publishPort = 2947;
            var localListenerEndpoint = new IPEndPoint(IPAddress.Any, listenPort);
            var localPublisherEndpoint = new IPEndPoint(IPAddress.Any, publishPort);
            var marineTrafficEndpoint = new IPEndPoint(IPAddress.Parse("5.9.207.224"), 11089);
            using (UdpClient localListener = new UdpClient(localListenerEndpoint))
            {
                while (!done)
                {
                    try
                    {
                        byte[] receivedData = localListener.Receive(ref localListenerEndpoint);
                        using (var marineTrafficClient = new UdpClient())
                            marineTrafficClient.Send(receivedData, receivedData.Length, marineTrafficEndpoint);
                        using (var localPublisherClient = new UdpClient())
                            localListener.Send(receivedData, receivedData.Length, localPublisherEndpoint);
                        Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [DEBUG] {1}", DateTime.Now, Encoding.ASCII.GetString(receivedData).TrimEnd('\n'));
                    }
                    catch (System.Exception ex)
                    {
                        Console.WriteLine("{0:yyyy-MM-dd HH:mm:ss} [ERROR] {1}", DateTime.Now, ex);
                    }
                }
            }
        }
    }
}
