#pragma once

#define ISAAC_SERVER_VERSION_MAJOR 1
#define ISAAC_SERVER_VERSION_MINOR 5
#define ISAAC_SERVER_VERSION_PATCH 0

#define ISAAC_PROTOCOL_VERSION_MAJOR 1
#define ISAAC_PROTOCOL_VERSION_MINOR 0

#include <boost/preprocessor/stringize.hpp>

#define ISAAC_SERVER_VERSION_STRING \
	BOOST_PP_STRINGIZE( ISAAC_SERVER_VERSION_MAJOR ) "." \
	BOOST_PP_STRINGIZE( ISAAC_SERVER_VERSION_MINOR ) "." \
	BOOST_PP_STRINGIZE( ISAAC_SERVER_VERSION_PATCH )
