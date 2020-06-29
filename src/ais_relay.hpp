#include <iostream>
#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/program_options.hpp>
#include <boost/regex.hpp>
#include <boost/xpressive/xpressive.hpp>

using boost::asio::ip::udp;

class ais_relay
{
private:
    bool _running;

    int _listen_port;
    int _broadcast_port;
    std::vector<std::string> _publish_endpoint_addresses;

    udp::socket *_listen_socket;
    udp::endpoint *_local_endpoint;

    udp::socket *_broadcast_socket;
    udp::endpoint *_broadcast_endpoint;

    std::vector<udp::endpoint> _publish_endpoints;

public:
    ais_relay(int listen_port, int broadcast_port, std::vector<std::string> udp_endpoint_addresses);
    ~ais_relay();

    void start();
};
