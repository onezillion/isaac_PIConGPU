# - Config file for the isaac package
# It defines the following variables
#  ISAAC_INCLUDE_DIRS     - include directories for FooBar
#  ISAAC_LIBRARIES        - libraries to link against
#  ISAAC_DEFINITIONS      - necessary definitions
#  ISAAC_FOUND            - whether ISAAC was found and is useable
#  ISAAC_DEPENDENCY_HINTS - hints about missing dependencies
#
# It defines the following options
#  ISAAC_RENDERER_LEGACY
#  ISAAC_RENDERER_OPTIMIZED
#  ISAAC_MORTON_CODE
#  ISAAC_THREADING
#  ISAAC_SHOWBORDER
#  ISAAC_JPEG
#  ISAAC_AO_BUG_FIX

###############################################################################
# ISAAC
###############################################################################
cmake_minimum_required (VERSION 3.3.0)


################################################################################
# CMake Policies
###############################################################################
# TODO update our VERSION syntax in project
#   https://cmake.org/cmake/help/v3.12/policy/CMP0048.html
if(POLICY CMP0048)
    cmake_policy(SET CMP0048 OLD)
endif()

# Search in <PackageName>_ROOT:
#   https://cmake.org/cmake/help/v3.12/policy/CMP0074.html
if(POLICY CMP0074)
    cmake_policy(SET CMP0074 NEW)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/ISAACBaseDir.cmake")

###############################################################################
# OPTIONS
###############################################################################
option(ISAAC_RENDERER_LEGACY "Compiles the legacy renderer" OFF)
if (ISAAC_RENDERER_LEGACY)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_RENDERER_LEGACY)
  message(STATUS "ISAAC_RENDERER_LEGACY is enabled") 
endif ()
option(ISAAC_RENDERER_OPTIMIZED "Compiles the optimized renderer" ON)
if (ISAAC_RENDERER_OPTIMIZED)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_RENDERER_OPTIMIZED)
  message(STATUS "ISAAC_RENDERER_OPTIMIZED is enabled") 
endif ()

if (NOT ISAAC_RENDERER_LEGACY AND NOT ISAAC_RENDERER_OPTIMIZED)
    message( WARNING "No renderer enabled, enable optimized or legacy renderer to allow the rendering of images!" )
endif ()

option(ISAAC_MORTON_CODE "(WARNING EXPERIMENTAL!) Enables usage of morton indexing for the optimized renderer" OFF)
if (ISAAC_MORTON_CODE)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_MORTON_CODE)
  message(STATUS "ISAAC_MORTON_CODE is enabled") 
endif ()

option(ISAAC_THREADING "Do the video and metadata transmission transport in background." ON)
if (ISAAC_THREADING)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_THREADING)
endif ()

option(ISAAC_SHOWBORDER "Debug and presentation mode, in which the sub volume borders are shown in black" OFF)
if (ISAAC_SHOWBORDER)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_SHOWBORDER)
endif ()

option(ISAAC_AO_BUG_FIX "fix ambient occlusion bug" ON)

###############################################################################
# JPEGLIB
###############################################################################
set( JPEG_DESCRIPTION "Use JPEG compression between visualization and isaac server. Deactivating will not work with big images. And with big I am talking about bigger than 800x600." )
option(ISAAC_JPEG ${JPEG_DESCRIPTION} ON)
if (ISAAC_JPEG)
        find_package(JPEG)
        if (JPEG_FOUND)
            # Checking whether the libjpeg-turbo extension JCS_EXT_RGBX is available
            file( READ ${JPEG_INCLUDE_DIR}/jpeglib.h JPEGHEADER )
            string( FIND "${JPEGHEADER}" "JCS_EXT_RGBX" JCS_EXT_RGBX_FOUND )
            if ( ${JCS_EXT_RGBX_FOUND} GREATER "-1" )
                set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${JPEG_INCLUDE_DIR})
                set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${JPEG_LIBRARY})
                set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} "-DISAAC_JPEG")
            else()
                set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   wrong libjpeg flavour found, needing libjpeg-turbo!")
                message( WARNING "wrong libjpeg flavour found, needing libjpeg-turbo!" )
                set( JPEG_FOUND FALSE )
            endif()
        endif(JPEG_FOUND)
        if (NOT JPEG_FOUND)
            set( ISAAC_JPEG OFF CACHE BOOL ${JPEG_DESCRIPTION} FORCE)
        endif(NOT JPEG_FOUND)
endif (ISAAC_JPEG)
if (NOT ISAAC_JPEG)
    set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   Using ISAAC without libjpeg is not recommended. Set ISAAC_JPEG to ON to enable libjpeg compression." )
    message( WARNING "Using ISAAC without libjpeg is not recommended. Set ISAAC_JPEG to ON to enable libjpeg compression." )
endif (NOT ISAAC_JPEG)

option(ISAAC_SPECULAR "Add the specular light component." ON)
if (ISAAC_SPECULAR)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_SPECULAR)
endif ()

option(ISAAC_VALGRIND_TWEAKS "Activates some tweaks, so that valgrind doesn't complain about some false founds" OFF)
if (ISAAC_VALGRIND_TWEAKS)
  set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DISAAC_VALGRIND_TWEAKS)
endif ()

set(ISAAC_DEPENDENCY_HINTS "missing dependencies:")

###############################################################################
# JANSSON LIB
###############################################################################
find_package (Jansson CONFIG QUIET)
if (Jansson_FOUND)
    set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${JANSSON_LIBRARIES})
    set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${JANSSON_INCLUDE_DIRS})
else()
    find_package (jansson CONFIG QUIET)
    if (TARGET jansson::jansson)
        # required since 2.12
        # interfacing cmake tagets with the old cmake variables we use in ISAAC
        # since ISSAC has CMake no target we can not use target_link_library
        get_target_property(JANSSON_LIBRARIES jansson::jansson LOCATION)
        set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${JANSSON_LIBRARIES})
        get_target_property(JANSSON_INCLUDE_DIRS jansson::jansson INTERFACE_INCLUDE_DIRECTORIES)
        set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${JANSSON_INCLUDE_DIRS})
    else()
        # jansson not found
        set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   jansson")
    endif()
endif()

###############################################################################
# PTHREADS
###############################################################################
find_package (Threads MODULE QUIET)
if (NOT Threads_FOUND)
    set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   pThreads")
endif()
set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} Threads::Threads)


################################################################################
# IceT LIB
################################################################################
# PATH_SUFFIXES is required because IceT is not following the CMake find_package folder structure
find_package (IceT CONFIG QUIET PATH_SUFFIXES "/lib/")
if (NOT IceT_FOUND)
    set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   IceT")
endif()
set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${ICET_CORE_LIBS})
set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${ICET_MPI_LIBS})
set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${ICET_INCLUDE_DIRS})


################################################################################
# BOOST LIB
################################################################################
find_package(Boost 1.56.0 MODULE QUIET)
if (NOT Boost_FOUND)
    set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   Boost")
endif()
set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${Boost_INCLUDE_DIR})
set(ISAAC_DEFINITIONS ${ISAAC_DEFINITIONS} -DBOOST_ALL_NO_LIB)

set(ISAAC_PRIVATE_FOUND true)


################################################################################
# Alpaka LIB
################################################################################

# alpaka target is already provided by another project
if(NOT TARGET alpaka::alpaka)
    set(isaac_MIN_ALPAKA_VERSION 0.6.0)
    find_package(alpaka ${isaac_MIN_ALPAKA_VERSION})
    if (NOT alpaka_FOUND)
        set(ISAAC_PRIVATE_FOUND false)
        set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   Alpaka")
    endif()
endif()

set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} "alpaka::alpaka")


################################################################################
# GLM LIB
################################################################################
find_package(glm 1.0.0 REQUIRED PATH_SUFFIXES "lib64/cmake/glm/" "lib/cmake/glm/")
set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} glm::glm)


################################################################################
# MPI LIB
################################################################################
find_package(MPI MODULE QUIET)
if (NOT MPI_FOUND)
    set(ISAAC_DEPENDENCY_HINTS ${ISAAC_DEPENDENCY_HINTS} "\n--   MPI")
endif()
set(ISAAC_INCLUDE_DIRS ${ISAAC_INCLUDE_DIRS} ${MPI_C_INCLUDE_PATH})
set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${MPI_C_LIBRARIES})
if (ISAAC_PRIVATE_FOUND)
    set(ISAAC_LIBRARIES ${ISAAC_LIBRARIES} ${MPI_CXX_LIBRARIES})
    if (MPI_CXX_FOUND AND MPI_C_FOUND)
        set(ISAAC_MPI_FOUND TRUE)
    endif()
else()
    set(ISAAC_MPI_FOUND ${MPI_C_FOUND})
endif()

################################################################################
# Warning if C++11 is not activated
################################################################################
if (CMAKE_CXX_STANDARD EQUAL 98)
    message( STATUS "At least C++ standard 11 must be enabled!" )
endif()


################################################################################
# Returning whether ISAAC could be found
################################################################################

FIND_PACKAGE_HANDLE_STANDARD_ARGS(ISAAC
                                    REQUIRED_VARS
                                        ISAAC_LIBRARIES
                                        ISAAC_INCLUDE_DIRS
                                        JANSSON_LIBRARIES
                                        JANSSON_INCLUDE_DIRS
                                        ISAAC_MPI_FOUND
                                        ICET_CORE_LIBS
                                        ICET_MPI_LIBS
                                        ICET_INCLUDE_DIRS
                                        Boost_FOUND
                                        ISAAC_PRIVATE_FOUND
                                )
