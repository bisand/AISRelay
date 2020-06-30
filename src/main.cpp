#include "ais_relay.hpp"

using namespace boost::program_options;

void to_cout(const std::vector<std::string> &v)
{
    std::copy(v.begin(), v.end(), std::ostream_iterator<std::string>{std::cout, "\n"});
}

int main(int argc, char **argv)
{
    bool debug = false;
    int listen_port;
    int broadcast_port;
    std::vector<std::string> publish_endpoint_addresses{};

    options_description desc{"Options"};
    desc.add_options()("help,h", "Help screen")("debug,d", "Debug mode.")("listen-port,l", value<int>()->default_value(10110), "Listen port")("broadcast-port,b", value<int>()->default_value(2947), "Broadcast port")("publish-endpoints,p", value<std::vector<std::string>>()->multitoken()->zero_tokens()->composing(), "Publish endpoints like MarineTraffic.\nFormat: <protocol>://<host>:<port>\nValid protocols: udp");

    command_line_parser parser{argc, argv};
    parser.options(desc).allow_unregistered().style(
        command_line_style::default_style |
        command_line_style::allow_slash_for_short);
    parsed_options parsed_options = parser.run();

    variables_map vm;
    store(parse_command_line(argc, argv, desc), vm);
    notify(vm);

    if (vm.count("help"))
    {
        std::cout << desc << '\n';
        return 0;
    }
    if (vm.count("debug"))
    {
        debug = true;
    }
    if (vm.count("listen-port"))
    {
        if (debug)
            std::cout << "Listen port: " << vm["listen-port"].as<int>() << '\n';
        listen_port = vm["listen-port"].as<int>();
    }
    if (vm.count("broadcast-port"))
    {
        if (debug)
            std::cout << "Broadcats port: " << vm["broadcast-port"].as<int>() << '\n';
        broadcast_port = vm["broadcast-port"].as<int>();
    }
    if (vm.count("publish-endpoints"))
    {
        if (debug)
            to_cout(vm["publish-endpoints"].as<std::vector<std::string>>());
        publish_endpoint_addresses = vm["publish-endpoints"].as<std::vector<std::string>>();
    }

    ais_relay aisrelay(listen_port, broadcast_port, publish_endpoint_addresses, debug);
    aisrelay.start();
    return 0;
}
