#include "HelloWorld.hpp"
#include <iostream>
#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>

using boost::asio::ip::udp;

void HelloWorld::say()
{
    try
    {

        boost::asio::io_service io_service;

        udp::endpoint local_endpoint = boost::asio::ip::udp::endpoint(boost::asio::ip::address::from_string("0.0.0.0"), boost::lexical_cast<int>(2947));
        std::cout << "Local bind " << local_endpoint << std::endl;

        udp::socket socket(io_service);
        socket.open(udp::v4());
        socket.bind(local_endpoint);

        while (true)
        {

            boost::array<char, 128> recv_buf;
            size_t len = socket.receive(boost::asio::buffer(recv_buf));
           std::cout.write(recv_buf.data(), len);
        }
    }
    catch (std::exception &e)
    {
        std::cerr << e.what() << std::endl;
    }
}