#include <boost/lexical_cast.hpp>
#include <iostream>


int main() {
  std::cout << "Hello c't Leser!\n"
            << "Boost: "
            << (BOOST_VERSION / 100000) << '.'
            << (BOOST_VERSION / 100 % 1000) << '.'
            << (BOOST_VERSION % 100) << '\n';
}
