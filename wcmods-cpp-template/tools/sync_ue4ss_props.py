#!/usr/bin/env python3
"""Writes UE4SS.props beside this mod's .vcxproj from wcmods' C++ build, so Visual Studio compiles and links the
mod the way `python wcmods.py cpp build` does.

    python tools/sync_ue4ss_props.py [<wcmods folder>]

wcmods builds C++ mods together with UE4SS's source, with Ninja, in <wcmods>/cache/cpp/out. Its build.ninja holds
what every mod gets: UE4SS's include folders, defines and libraries, and CMakeCache.txt the compiler that built
them (UE4SS's libraries are whole-program optimised, so a mod has to link with that very compiler version, or the
link stops with C1047). This reads those, writes $(WCModsRoot) (which wcmods.props sets) in place of the wcmods
folder in every path, and writes UE4SS.props.

Run it again after `cpp setup` and `cpp build` have moved UE4SS to another version, or after a Visual Studio
update rebuilt it. It needs `cpp build` to have run once, for any mod (the C++ SDK's test mod will do:
`python wcmods.py cpp build tests/cpp-sdk`).

Without a folder, wcmods is looked for two folders up (this mod sitting in wcmods' mods/), then as a
warrior-cats-mods folder beside this one, then as one beside the folder this one is in (this template in a
wcmods-examples checkout, next to a warrior-cats-mods checkout), the way wcmods.props guesses.
"""
import datetime
import os
import re
import subprocess
import sys
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
OUT = os.path.join(PROJECT, "UE4SS.props")

# Compiler and linker flags the .vcxproj sets by hand (its ClCompile and Link settings), so they aren't copied
# here; one build.ninja has that isn't in this list is pointed out, to add to the .vcxproj.
KNOWN_COMPILE = {"/EHsc", "-std:c++latest", "/std:c++latest", "-MD", "/MD", "/W3", "/wd4005", "/wd4251", "/wd4068",
                 "/wd4201", "/Zc:inline", "/Zc:strictStrings", "/Gy", "/MP", "/Zc:preprocessor", "/Zi", "/O2", "/Ob2",
                 "/utf-8", "/permissive-", "/Zc:lambda", "-external:W0", "/external:W0"}
KNOWN_LINK = {"/machine:x64", "/DEBUG:FULL", "/LTCG", "/INCREMENTAL:NO", "/OPT:REF", "/OPT:ICF"}
# Defines the configurations set themselves, and the one CMake gives each mod's target.
PER_CONFIG = {"NDEBUG"}


def find_wcmods(given):
    """The wcmods folder: the one given, or guessed as wcmods.props does."""
    candidates = [given] if given else [os.path.join(PROJECT, "..", ".."),
                                        os.path.join(PROJECT, "..", "warrior-cats-mods"),
                                        os.path.join(PROJECT, "..", "..", "warrior-cats-mods")]
    for c in candidates:
        if c and os.path.isfile(os.path.join(c, "wcmods.py")):
            return os.path.abspath(c)
    if given:
        sys.exit(f"{given} isn't a wcmods folder (no wcmods.py in it)")
    sys.exit("can't find wcmods: give its folder, e.g. python tools/sync_ue4ss_props.py C:\\path\\to\\warrior-cats-mods")


def unescape_ninja(text):
    return text.replace("$:", ":").replace("$ ", " ").replace("$$", "$")


def tokens(value):
    """A command line's words, quoted parts kept whole."""
    return re.findall(r'(?:"[^"]*"|\S)+', value)


def statements(ninja):
    """Each `build` statement of build.ninja: (outputs line, {variable: value})."""
    out = []
    lines = ninja.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].startswith("build "):
            head, vars_ = lines[i], {}
            i += 1
            while i < len(lines) and lines[i].startswith("  ") and " = " in lines[i]:
                key, _, value = lines[i].strip().partition(" = ")
                vars_[key] = unescape_ninja(value)
                i += 1
            out.append((unescape_ninja(head), vars_))
        else:
            i += 1
    return out


def mod_build(ninja):
    """The compile and link variables of one wcmods mod target in build.ninja: any will do, as UE4SS's part of
    them is the same for every mod."""
    compile_, link, target = None, None, None
    for head, vars_ in statements(ninja):
        m = re.match(r"build mods\\(wcmods_\w+)\\CMakeFiles\\\1\.dir\\.+\.obj: CXX_COMPILER", head)
        if m and compile_ is None:
            compile_, target = vars_, m.group(1)
            continue
        if target and re.match(rf"build wcmods\\{re.escape(target)}\\main\.dll\b", head):
            link = vars_
            break
    if not compile_ or not link:
        sys.exit("build.ninja has no wcmods mod in it yet: run `python wcmods.py cpp build tests/cpp-sdk` (or any C++ "
                 "mod) in wcmods first")
    return target, compile_, link


def under(path, folder):
    path, folder = os.path.normcase(os.path.normpath(path)), os.path.normcase(os.path.normpath(folder))
    return path == folder or path.startswith(folder + os.sep)


def rooted(path, root):
    """A path under the wcmods folder, written from $(WCModsRoot)."""
    path = os.path.normpath(path)
    if under(path, root):
        return "$(WCModsRoot)" + path[len(os.path.normpath(root)):]
    return path


def main():
    root = find_wcmods(sys.argv[1] if len(sys.argv) > 1 else None)
    out_dir = os.path.join(root, "cache", "cpp", "out")
    ninja_path = os.path.join(out_dir, "build.ninja")
    cache_path = os.path.join(out_dir, "CMakeCache.txt")
    if not os.path.isfile(ninja_path) or not os.path.isfile(cache_path):
        sys.exit(f"UE4SS isn't built in {out_dir} yet: in {root} run `python wcmods.py cpp setup`, then "
                 "`python wcmods.py cpp build tests/cpp-sdk` (or any C++ mod)")
    with open(ninja_path, encoding="utf-8", errors="replace") as f:
        target, compile_, link = mod_build(f.read())
    with open(cache_path, encoding="utf-8", errors="replace") as f:
        cache = f.read()

    # The compiler: its version pins the toolset Visual Studio uses, and names the toolset family.
    compiler = re.search(r"^CMAKE_CXX_COMPILER:FILEPATH=(.+)$", cache, re.M)
    version = re.search(r"MSVC[\\/](\d+)\.(\d+)\.(\d+)", compiler.group(1)) if compiler else None
    tools_version, toolset = "", ""
    if version:
        major, minor = int(version.group(1)), int(version.group(2))
        tools_version = ".".join(version.groups())
        toolset = {14: {1: "v141", 2: "v142", 3: "v143", 4: "v143", 5: "v145"}.get(minor // 10, "")}.get(major, "")
    if not toolset:
        print(f"note: can't tell the Visual Studio toolset from {compiler.group(1) if compiler else 'CMakeCache.txt'}; "
              "the .vcxproj will use this Visual Studio's newest")

    # Defines: UE4SS's, from the mod's DEFINES and the -D flags among FLAGS, without the target's own and the
    # ones the configurations set.
    defines, includes, external, unknown = [], [], [], []
    for tok in tokens(compile_.get("DEFINES", "")) + tokens(compile_.get("FLAGS", "")):
        if tok[:2] in ("-D", "/D"):
            # A string define is -DNAME=\"text\" on Ninja's command line; MSBuild wants the quotes bare
            # (NAME="text") and escapes them itself.
            d = tok[2:].replace('\\"', '"')
            if d == f"{target}_EXPORTS" or d.split("=")[0] in PER_CONFIG:
                continue
            if d not in defines:
                defines.append(d)
        elif tok[:2] in ("-I", "/I"):
            includes.append(tok[2:].strip('"'))
        elif tok.startswith(("-external:I", "/external:I")):
            external.append(tok[len("-external:I"):].strip('"'))
        elif tok not in KNOWN_COMPILE:
            unknown.append(tok)
    for tok in tokens(compile_.get("INCLUDES", "")):
        if tok[:2] in ("-I", "/I"):
            includes.append(tok[2:].strip('"'))
        elif tok.startswith(("-external:I", "/external:I")):
            external.append(tok[len("-external:I"):].strip('"'))
        elif tok not in KNOWN_COMPILE:
            unknown.append(tok)
    # The mod's own folders (its src/) are the .vcxproj's business; UE4SS's and the SDK's stay.
    sdk = os.path.join(root, "wcmods", "cpp_sdk")
    cache_dir = os.path.join(root, "cache")
    includes = [rooted(p, root) for p in includes if under(p, cache_dir) or under(p, sdk)]
    external = [rooted(p, root) for p in external if under(p, cache_dir) or under(p, sdk)]

    # Libraries: UE4SS's are relative to the build folder; the system's are bare names.
    libraries, lib_dir = [], ""
    for tok in tokens(link.get("LINK_LIBRARIES", "")):
        tok = tok.strip('"')
        if not tok.lower().endswith(".lib"):
            continue
        if "\\" in tok or "/" in tok:
            full = tok if os.path.isabs(tok) else os.path.join(out_dir, tok)
            if os.path.basename(tok).lower() == "ue4ss.lib":
                lib_dir = rooted(os.path.dirname(full), root)
            tok = rooted(full, root)
        if tok not in libraries:
            libraries.append(tok)
    for tok in tokens(link.get("LINK_FLAGS", "")):
        if tok not in KNOWN_LINK:
            unknown.append(tok)
    if not lib_dir:
        sys.exit("the mod's link line has no UE4SS.lib in it; is this a wcmods C++ build?")

    # The UE4SS commit the source is at: what dlls/build.json names.
    src = os.path.join(root, "cache", "ue4ss-src")
    commit = ""
    try:
        commit = subprocess.run(["git", "-C", src, "rev-parse", "HEAD"], capture_output=True, text=True,
                                timeout=30).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        head = os.path.join(src, ".git", "HEAD")
        if os.path.isfile(head):
            with open(head, encoding="utf-8") as f:
                text = f.read().strip()
            commit = text if re.fullmatch(r"[0-9a-f]{40}", text) else ""
    if not commit:
        print(f"note: can't tell which UE4SS commit {src} is at (no git?); dlls/build.json won't be written, and an "
              "install will warn that it can't tell which UE4SS the DLL is for")

    config = compile_.get("CONFIG") or link.get("CONFIG") or "Game__Shipping__Win64"
    today = datetime.date.today().isoformat()

    def prop(name, value):
        return f"    <{name}>{escape(value, {chr(34): '&quot;'})}</{name}>"

    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        f"<!-- Written by tools/sync_ue4ss_props.py on {today} from {out_dir}: UE4SS {commit[:8] or '?'} "
        f"({config}), built with MSVC {tools_version or '?'} ({toolset or 'default toolset'}).",
        "     Don't edit: run the script again instead, after `cpp setup` or `cpp build` change UE4SS. Paths start at",
        "     $(WCModsRoot), which wcmods.props sets. -->",
        '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">',
        "  <PropertyGroup>",
        prop("UE4SSCommit", commit),
        prop("UE4SSConfig", config),
        prop("UE4SSToolsVersion", tools_version),
        prop("UE4SSPlatformToolset", toolset),
        prop("UE4SSLibDir", lib_dir),
        prop("UE4SSIncludeDirs", ";".join(includes)),
        prop("UE4SSExternalIncludeDirs", ";".join(external)),
        prop("UE4SSDefines", ";".join(defines)),
        prop("UE4SSLibraries", ";".join(libraries)),
        "  </PropertyGroup>",
        "</Project>",
    ]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {OUT}: UE4SS {commit[:8] or '?'}, MSVC {tools_version or '?'}, {len(includes)} include folders, "
          f"{len(external)} external, {len(defines)} defines, {len(libraries)} libraries")
    if unknown:
        print("note: build.ninja has flags the .vcxproj doesn't set; look at its ClCompile and Link settings:\n  "
              + " ".join(sorted(set(unknown))))


if __name__ == "__main__":
    main()
