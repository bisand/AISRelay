#include "ais_relay.hpp"

ais_relay::ais_relay(int listen_port, int broadcast_port, std::vector<std::string> publish_endpoint_addresses, bool debug)
{
    _debug = debug;
    _listen_port = listen_port;
    _broadcast_port = broadcast_port;
    _publish_endpoint_addresses = publish_endpoint_addresses;

    boost::asio::io_service io_service;

    _local_endpoint = new boost::asio::ip::udp::endpoint(boost::asio::ip::address::from_string("0.0.0.0"), boost::lexical_cast<int>(_listen_port));
    _broadcast_endpoint = new boost::asio::ip::udp::endpoint(boost::asio::ip::address_v4::broadcast(), boost::lexical_cast<int>(_broadcast_port));
    if (_debug)
    {
        std::cout << "Local bind " << *_local_endpoint << std::endl;
        std::cout << "Broadcast to " << *_broadcast_endpoint << std::endl;
    }
    _listen_socket = new udp::socket(io_service);
    _listen_socket->open(udp::v4());
    _listen_socket->bind(*_local_endpoint);

    _broadcast_socket = new udp::socket(io_service);
    _broadcast_socket->open(udp::v4());
    _broadcast_socket->set_option(boost::asio::socket_base::broadcast(true));

    for (size_t i = 0; i < _publish_endpoint_addresses.size(); i++)
    {
        std::string url = _publish_endpoint_addresses[i];
        boost::xpressive::sregex rx = boost::xpressive::sregex::compile("^(?P<protocol>udp|tcp)?(?:://)?(?P<host>[a-z0-9.]+)(?::(?P<port>[0-9]{1,5}))?");
        boost::xpressive::smatch what;
        if (boost::xpressive::regex_search(url, what, rx))
        {
            std::string protocol = "udp";
            std::string host = what["host"];
            int port = 2947;

            if (what["protocol"].matched)
                protocol = what["protocol"];
            if (what["port"].matched)
                port = boost::lexical_cast<int>(what["port"]);

            // ONly UDP support
            if (protocol == "udp")
            {
                std::string port_num = boost::lexical_cast<std::string>(port);
                boost::asio::ip::udp::resolver::query resolver_query(host, port_num, boost::asio::ip::udp::resolver::query::numeric_service);
                boost::asio::ip::udp::resolver resolver(io_service);
                boost::system::error_code ec;
                boost::asio::ip::udp::resolver::iterator it = resolver.resolve(resolver_query, ec);

                if (ec.value() != 0)
                {
                    std::cout << "Failed to resolve a DNS name."
                              << "Error code = " << ec.value()
                              << ". Message = " << ec.message();
                    throw 404;
                }

                boost::asio::ip::udp::resolver::iterator it_end;

                for (; it != it_end; ++it)
                {
                    boost::asio::ip::udp::endpoint ep = it->endpoint();
                    _publish_endpoints.push_back(ep);
                }

                if (_debug)
                {
                    std::cout << "Publishing to " << protocol << "," << host << "," << port << std::endl;
                }
            }
        }
    }
}

ais_relay::~ais_relay()
{
    _broadcast_socket->close();
    _listen_socket->close();
    delete _broadcast_socket;
    delete _listen_socket;
    delete _broadcast_endpoint;
    delete _local_endpoint;
    _publish_endpoints.clear();
    _publish_endpoint_addresses.clear();
}

void ais_relay::start()
{
    _running = true;
    try
    {
        if (_debug)
            std::cout << "Starting..." << std::endl;
        while (_running)
        {
            boost::array<char, 1024> recv_buf;
            recv_buf.fill(0);
            size_t len = _listen_socket->receive(boost::asio::buffer(recv_buf));
            if (_debug)
                std::cout.write(recv_buf.data(), len);
            _broadcast_socket->send_to(boost::asio::buffer(recv_buf), *_broadcast_endpoint);
            for (size_t i = 0; i < _publish_endpoints.size(); i++)
            {
                boost::asio::io_service io_service;
                udp::endpoint publish_endpoint = _publish_endpoints[i];
                udp::socket publish_socket(io_service);
                publish_socket.open(udp::v4());
                publish_socket.send_to(boost::asio::buffer(recv_buf), publish_endpoint);
                publish_socket.close();
            }
        }
    }
    catch (std::exception &e)
    {
        std::cerr << e.what() << std::endl;
    }
}