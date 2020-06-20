#include "AISRelay.hpp"

using namespace boost::program_options;

void to_cout(const std::vector<std::string> &v)
{
  std::copy(v.begin(), v.end(), std::ostream_iterator<std::string>{
    std::cout, "\n"});
}

int main(int argc, char **argv)
{
    options_description desc{"Options"};
    desc.add_options()
        ("help,h", "Help screen")
        ("listen-port,l", value<int>()->default_value(10110), "Listen port")
        ("broadcast-port,b", value<int>()->default_value(2947), "Broadcast port")
        ("udp-endpoints,u", value<std::vector<std::string>>()->multitoken()->zero_tokens()->composing(), "UDP endpoints such as MarineTraffic. Separated with space. Format: <ipaddr>:<port>");

    command_line_parser parser{argc, argv};
    parser.options(desc).allow_unregistered().style(
      command_line_style::default_style |
      command_line_style::allow_slash_for_short);
    parsed_options parsed_options = parser.run();

    variables_map vm;
    store(parse_command_line(argc, argv, desc), vm);
    notify(vm);

    if (vm.count("help"))
        std::cout << desc << '\n';
    if (vm.count("listen-port"))
        std::cout << "Listen port: " << vm["listen-port"].as<int>() << '\n';
    if (vm.count("broadcast-port"))
        std::cout << "Broadcats port: " << vm["broadcast-port"].as<int>() << '\n';
    if (vm.count("udp-endpoints"))
        to_cout(vm["udp-endpoints"].as<std::vector<std::string>>());

    return 0;

    AISRelay aisrelay;
    aisrelay.start();
    return 0;
}
