#include "AISRelay.hpp"

ais_relay::ais_relay(int listen_port, int broadcast_port, std::vector<std::string> udp_endpoint_addresses)
{
    _listen_port = listen_port;
    _broadcast_port = broadcast_port;
    _udp_endpoint_addresses = udp_endpoint_addresses;

    boost::asio::io_service io_service;

    _local_endpoint = new boost::asio::ip::udp::endpoint(boost::asio::ip::address::from_string("0.0.0.0"), boost::lexical_cast<int>(_listen_port));
    _broadcast_endpoint = new boost::asio::ip::udp::endpoint(boost::asio::ip::address_v4::broadcast(), boost::lexical_cast<int>(_broadcast_port));
    std::cout << "Local bind " << *_local_endpoint << std::endl;
    std::cout << "Broadcast to " << *_broadcast_endpoint << std::endl;

    _listen_socket = new udp::socket(io_service);
    _listen_socket->open(udp::v4());
    _listen_socket->bind(*_local_endpoint);

    _broadcast_socket = new udp::socket(io_service);
    _broadcast_socket->open(udp::v4());
    _broadcast_socket->set_option(boost::asio::socket_base::broadcast(true));

    for (size_t i = 0; i < _udp_endpoint_addresses.size(); i++)
    {
        std::string url = _udp_endpoint_addresses[i];
        boost::regex ex("^(?<protocol>(udp|tcp))://((?<subdomain>[a-z0-9]{0,10}.{1}){0,2}(?<domain>[a-z0-9]{1,30}){1}.{1}(?<extension>[a-z]{1,10}){1}|(?<ipaddress>([0-9.]{2,5}){3,8}))(?<port>:[0-9]{1,6}){0,1}$");
        boost::smatch what;
        if (regex_match(url, what, ex))
        {
            auto matches = what.begin();
            for (size_t j = 0; j < what.size(); j++)
            {
                std::cout << "Publish to " << i << matches[j] << std::endl;
            }
            
            // boost::asio::ip::address address = boost::asio::ip::address::from_string(what[2]);
            // int port = boost::lexical_cast<int>(what[3].str());
            // boost::asio::ip::udp::endpoint publish_endpoint(address, port);
            // _udp_endpoints.push_back(publish_endpoint);
            // std::cout << "Publish to " << publish_endpoint << std::endl;
        }
    }
}

ais_relay::~ais_relay()
{
    delete _broadcast_socket;
    delete _listen_socket;
    delete _broadcast_endpoint;
    delete _local_endpoint;
}

void ais_relay::start()
{
    _running = true;
    try
    {
        while (_running)
        {
            boost::array<char, 1024> recv_buf;
            size_t len = _listen_socket->receive(boost::asio::buffer(recv_buf));
            std::cout.write(recv_buf.data(), len);
            _broadcast_socket->send_to(boost::asio::buffer(recv_buf), *_broadcast_endpoint);
            for (size_t i = 0; i < _udp_endpoints.size(); i++)
            {
                boost::asio::io_service io_service;
                udp::endpoint publish_endpoint = _udp_endpoints[i];
                udp::socket publish_socket(io_service);
                publish_socket.send_to(boost::asio::buffer(recv_buf), publish_endpoint);
            }
        }
    }
    catch (std::exception &e)
    {
        std::cerr << e.what() << std::endl;
    }
}