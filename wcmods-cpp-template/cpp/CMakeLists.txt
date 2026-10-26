# This mod's C++ for wcmods' own build, `python wcmods.py cpp build <this mod's folder>`, which makes dlls/main.dll
# the same way the Visual Studio solution beside this folder does. wcmods_mod (wcmods/cpp_sdk/WCMods.cmake) makes
# the DLL, linked against UE4SS, with WCMods.hpp and src/ on the include path; anything else CMake can do
# (FetchContent, target_link_libraries) goes after it. docs/SDK.md in wcmods, "C++ mods".
#
# A new .cpp goes in this list and in the .vcxproj (Source Files), so both builds see it.
wcmods_mod(${WCMODS_TARGET}
    src/main.cpp
)
