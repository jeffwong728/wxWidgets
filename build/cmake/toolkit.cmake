#############################################################################
# Name:        build/cmake/toolkit.cmake
# Purpose:     CMake platform toolkit options
# Author:      Tobias Taschner
# Created:     2016-10-03
# Copyright:   (c) 2016 wxWidgets development team
# Licence:     wxWindows licence
#############################################################################

# Options required for toolkit selection/detection
wx_option(wxUSE_GUI "Use GUI" ON)

if(CMAKE_OSX_SYSROOT MATCHES iphoneos)
    set(IPHONE ON)

    # workaround a bug where try_compile (and functions using it,
    # like find_package, check_c_source_compiles) fails
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
endif()

if(WIN32)
    set(wxDEFAULT_TOOLKIT msw)
    set(wxTOOLKIT_OPTIONS msw gtk2 gtk3 qt)
    set(wxPLATFORM WIN32)
elseif(APPLE AND IPHONE)
    set(wxDEFAULT_TOOLKIT osx_iphone)
    set(wxTOOLKIT_OPTIONS osx_iphone)
    set(wxPLATFORM OSX)
elseif(APPLE)
    set(wxDEFAULT_TOOLKIT osx_cocoa)
    set(wxTOOLKIT_OPTIONS osx_cocoa gtk2 gtk3 gtk4 qt)
    set(wxPLATFORM OSX)
elseif(UNIX)
    set(wxDEFAULT_TOOLKIT gtk3)
    set(wxTOOLKIT_OPTIONS gtk2 gtk3 gtk4 motif qt)
    set(wxPLATFORM UNIX)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

wx_option(wxBUILD_TOOLKIT "Toolkit used by wxWidgets" ${wxDEFAULT_TOOLKIT}
    STRINGS ${wxTOOLKIT_OPTIONS})
# TODO: set to univ for universal build
set(wxBUILD_WIDGETSET "")

# Create shortcut variable for easy toolkit tests
string(TOUPPER ${wxBUILD_TOOLKIT} toolkit_upper)
set(WX${toolkit_upper} ON)
if(wxBUILD_TOOLKIT MATCHES "^gtk*")
    set(WXGTK ON)
elseif(wxBUILD_TOOLKIT MATCHES "^osx*")
    set(WXOSX ON)
elseif(wxBUILD_TOOLKIT MATCHES "qt")
    set(WXQT ON)
endif()

set(wxTOOLKIT_DEFINITIONS __WX${toolkit_upper}__)

if(NOT wxUSE_GUI)
    set(wxBUILD_TOOLKIT "base")
    string(TOUPPER ${wxBUILD_TOOLKIT} toolkit_upper)
    set(WX${toolkit_upper} ON)
    set(wxTOOLKIT_DEFINITIONS __WX${toolkit_upper}__)
endif()

# Initialize toolkit variables
if(wxUSE_GUI)
set(wxTOOLKIT_INCLUDE_DIRS)
set(wxTOOLKIT_LIBRARIES)
set(wxTOOLKIT_VERSION)

if(UNIX AND NOT APPLE AND NOT WIN32)
    find_package(X11 REQUIRED)
    list(APPEND wxTOOLKIT_INCLUDE_DIRS ${X11_INCLUDE_DIR})
    list(APPEND wxTOOLKIT_LIBRARIES ${X11_LIBRARIES})
endif()

if(WXGTK AND NOT WIN32 AND NOT MSVC)
    if(WXGTK4)
        set(gtk_lib GTK4)
    elseif(WXGTK3)
        set(gtk_lib GTK3)
    elseif(WXGTK2)
        set(gtk_lib GTK2)
    endif()

    find_package(${gtk_lib} REQUIRED)
    list(APPEND wxTOOLKIT_INCLUDE_DIRS ${${gtk_lib}_INCLUDE_DIRS})
    list(APPEND wxTOOLKIT_LIBRARIES ${${gtk_lib}_LIBRARIES})
    list(APPEND wxTOOLKIT_DEFINITIONS ${${gtk_lib}_DEFINITIONS})
    list(APPEND wxTOOLKIT_DEFINITIONS __WXGTK__)
    set(wxTOOLKIT_VERSION ${${gtk_lib}_VERSION})

    if(WIN32 AND MSVC)
        if(WXGTK4)
            list(APPEND wxTOOLKIT_LIBRARIES
                libgtk-4.dll.a
                libgdk-4.dll.a
            )
        elseif(WXGTK3)
            list(APPEND wxTOOLKIT_LIBRARIES
                libgtk-3.dll.a
                libgdk-3.dll.a
            )
        elseif(WXGTK2)
            list(APPEND wxTOOLKIT_LIBRARIES
                gtk-win32-2.0
                gdk-win32-2.0
            )
        endif()
        list(APPEND wxTOOLKIT_LIBRARIES
            gio-2.0
            pangocairo-1.0
            gdk_pixbuf-2.0
            cairo
            pango-1.0
            gobject-2.0
            gthread-2.0
            glib-2.0
        )
    endif()
endif()

if(WXGTK AND WIN32 AND MSVC)
    set(VLIBDIR "$ENV{VCPKG_DIR}/lib")
    set(VLIBDIRD "$ENV{VCPKG_DIR}/debug/lib")

    include(SelectLibraryConfigurations)
    include(FindPackageHandleStandardArgs)
    macro(FindVCPkgLibrary LIBNAME LIB_D LIB_R)
            find_library(${LIBNAME}_LIBRARY_DEBUG NAMES ${LIB_D} PATHS "$ENV{VCPKG_DIR}/debug/lib" NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH)
            find_library(${LIBNAME}_LIBRARY_RELEASE NAMES ${LIB_R} PATHS "$ENV{VCPKG_DIR}/lib" NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH)
            select_library_configurations(${LIBNAME})
            find_package_handle_standard_args(${LIBNAME} FOUND_VAR ${LIBNAME}_FOUND REQUIRED_VARS ${LIBNAME}_LIBRARY)
    endmacro()

    find_library(CAIRO_LIBRARY_DEBUG NAMES cairod PATHS "$ENV{VCPKG_DIR}/debug/lib" NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH)
    find_library(CAIRO_LIBRARY_RELEASE NAMES cairo PATHS "$ENV{VCPKG_DIR}/lib" NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH)

    FindVCPkgLibrary(GTK3 gtk-3.0 gtk-3.0)
    FindVCPkgLibrary(GDK3 gdk-3.0 gdk-3.0)
    FindVCPkgLibrary(GIO gio-2.0 gio-2.0)
    FindVCPkgLibrary(GLIB glib-2.0 glib-2.0)
    FindVCPkgLibrary(CAIRO cairod cairo)
    FindVCPkgLibrary(PANGOCAIRO pangocairo-1.0 pangocairo-1.0)
    FindVCPkgLibrary(GDK_PIXBUF gdk_pixbuf-2.0 gdk_pixbuf-2.0)
    FindVCPkgLibrary(PANGO pango-1.0 pango-1.0)
    FindVCPkgLibrary(GOBJECT gobject-2.0 gobject-2.0)
    FindVCPkgLibrary(GTHREAD gthread-2.0 gthread-2.0)

    list(APPEND wxTOOLKIT_INCLUDE_DIRS "$ENV{VCPKG_DIR}/include")
    list(APPEND wxTOOLKIT_LIBRARIES "${GTK3_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GDK3_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${CAIRO_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GIO_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${PANGOCAIRO_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GDK_PIXBUF_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${PANGO_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GOBJECT_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GTHREAD_LIBRARY}")
    list(APPEND wxTOOLKIT_LIBRARIES "${GLIB_LIBRARY}")
    list(APPEND wxTOOLKIT_DEFINITIONS __WXGTK__)
    set(wxTOOLKIT_VERSION 3.22.19)
endif()

if(WXQT)
    set(QT_COMPONENTS Core Widgets Gui OpenGL Test)
    foreach(QT_COMPONENT ${QT_COMPONENTS})
        find_package(Qt5 COMPONENTS ${QT_COMPONENT} REQUIRED)
        list(APPEND wxTOOLKIT_INCLUDE_DIRS ${Qt5${QT_COMPONENT}_INCLUDE_DIRS})
        list(APPEND wxTOOLKIT_LIBRARIES ${Qt5${QT_COMPONENT}_LIBRARIES})
        list(APPEND wxTOOLKIT_DEFINITIONS ${Qt5${QT_COMPONENT}_COMPILE_DEFINITIONS})
    endforeach()
    set(wxTOOLKIT_VERSION ${Qt5Core_VERSION})
endif()

if(APPLE)
    list(APPEND wxTOOLKIT_DEFINITIONS __WXMAC__ __WXOSX__)
endif()

endif() # wxUSE_GUI
