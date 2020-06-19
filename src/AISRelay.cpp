#include "AISRelay.hpp"
#include <iostream>
#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>

using boost::asio::ip::udp;

void AISRelay::say()
{
    try
    {
        boost::asio::io_service io_service;

        udp::endpoint local_endpoint = boost::asio::ip::udp::endpoint(boost::asio::ip::address::from_string("0.0.0.0"), boost::lexical_cast<int>(2947));
        udp::endpoint broadcast_endpoint = boost::asio::ip::udp::endpoint(boost::asio::ip::address_v4::broadcast(), boost::lexical_cast<int>(2948));
        std::cout << "Local bind " << local_endpoint << std::endl;
        std::cout << "Broadcast to " << broadcast_endpoint << std::endl;

        udp::socket listen_socket(io_service);
        udp::socket broadcast_socket(io_service);
        listen_socket.open(udp::v4());
        listen_socket.bind(local_endpoint);
        broadcast_socket.open(udp::v4());
        broadcast_socket.set_option(boost::asio::socket_base::broadcast(true));

        while (true)
        {
            boost::array<char, 1024> recv_buf;
            size_t len = listen_socket.receive(boost::asio::buffer(recv_buf));
            std::cout.write(recv_buf.data(), len);
            broadcast_socket.send_to(boost::asio::buffer(recv_buf), broadcast_endpoint);
        }
    }
    catch (std::exception &e)
    {
        std::cerr << e.what() << std::endl;
    }
}