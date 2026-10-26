# C++ mod template for wcmods

A starting point for a C++ mod for *Warrior Cats: Clans of the Forest*, built with
[wcmods](https://github.com/HexOffender/warrior-cats-mods) and its C++ SDK, with a Visual Studio solution.
The mod it starts as keeps your cat's stamina full while its setting is on, heals your cat on F7, and has a
page in the mod menu. It lives in [wcmods-examples](https://github.com/HexOffender/wcmods-examples) beside
the other example mods; copy the folder to start yours.

```
wcmods-cpp-template/
  mod.json                          the mod: its name, description, version
  settings.json                     its settings; wcmods::settings() in the code, a page in the mod menu
  cpp/src/main.cpp                  the mod
  cpp/CMakeLists.txt                how wcmods' own build (`cpp build`) builds it
  wcmods-cpp-template.sln           the Visual Studio solution, and its project (.vcxproj)
  wcmods.props                      where wcmods is (guessed; set it here if the guess is wrong)
  tools/sync_ue4ss_props.py         writes UE4SS.props: UE4SS's include folders, defines and libraries, and the
                                    compiler that built it, from wcmods' build. Run it before the first build
  UE4SS.props                       what the script writes; git ignores it, as it names your UE4SS and compiler
  dlls/main.dll, dlls/build.json    what a build makes: the mod, and the UE4SS it's for (git ignores dlls/)
  .gitignore                        leaves out what a build makes, UE4SS.props, and your wcmods.local.props
```

## What it needs

A C++ mod links against UE4SS itself, at the very version the game has, so it's built with UE4SS's source.
wcmods gets and builds that for you, once:

1. **wcmods**, set up with the game (Clan Mod Studio's "Get set up", UE4SS installed), with code mods
   allowed (`"allow_code_mods": true` in its `wcmods.json`, or Options on the studio's Mods page).
2. **Visual Studio 2022 or later** with "Desktop development with C++" (Community is free), plus **Rust**
   and **git**, and a GitHub account linked to an Epic Games account for UE4SS's Unreal headers. wcmods'
   `docs/SDK.md`, "C++ mods", explains each.
3. In the wcmods folder:
   ```
   python wcmods.py cpp setup
   python wcmods.py cpp build tests/cpp-sdk
   ```
   `cpp setup` gets UE4SS's source at the game's version; the first `cpp build` compiles UE4SS (several
   minutes, once). It builds the SDK's test mod: the sync script reads from that build what every mod gets,
   and what it leaves in `cache/cpp/out` (UE4SS's libraries) is what this solution links.

## Making your mod

1. **Copy this folder** (from a checkout of wcmods-examples, or its .zip) and name it after your mod: the
   folder's name is the mod's id (lowercase letters, digits, `-`, `_`), so `my-mod`, not `My Mod`. Put it
   in wcmods' `mods/` folder to work on it in place, or anywhere.
2. **Tell it where wcmods is**, unless it can guess: `wcmods.props` looks two folders up (the mod in
   wcmods' `mods/`), then for a `warrior-cats-mods` folder beside the mod, then for one beside the folder
   the mod is in (this template in `D:\projects\wcmods-examples`, say, finds
   `D:\projects\warrior-cats-mods`). Otherwise set `WCModsRoot` in it, or in a `wcmods.local.props` beside
   it with the same lines (git ignores that one).
3. **`python tools\sync_ue4ss_props.py`**, from the mod's folder, before the first build: writes
   `UE4SS.props` from wcmods' build (UE4SS's include folders, defines and libraries, and the compiler
   version that built it). Git ignores the file, since it names your UE4SS version and Visual Studio; the
   solution won't build without it, and says so. Visual Studio reads the file as it opens the solution, so
   if the solution was open, close and reopen it. Run the script again whenever `cpp setup` or `cpp build`
   move UE4SS to another version, or a Visual Studio update rebuilds it.
4. **Open the .sln**, pick **Release**, and build (Ctrl+Shift+B). It makes `dlls\main.dll` and
   `dlls\build.json`.
5. **Edit `mod.json`** (name, description, author) and **`cpp\src\main.cpp`**. Every call the SDK has is in
   wcmods' [docs/SDK.md](https://github.com/HexOffender/warrior-cats-mods/blob/main/docs/SDK.md#c-mods),
   "C++ mods"; `WCMods.hpp` is the one header to include. A new `.cpp` goes in the project (Source Files)
   and in `cpp\CMakeLists.txt`, so wcmods' own build sees it too.
6. **Put it in the game.** A mod in wcmods' `mods/` folder goes in with Play in Clan Mod Studio, or
   `python wcmods.py install`. One anywhere else: `python wcmods.py add <the mod's folder>` copies it into
   `mods/` first. The game must be closed. In the game, the mod's lines are in UE4SS's log
   (`Wrc\Binaries\Win64\ue4ss\UE4SS.log`), and its page in the mod menu (Insert).

**Debugging:** build **Debug** (no optimisation for the mod's own code; it still links UE4SS's shipping
build, the one the game has), install, start the game, then Debug > Attach to Process >
`Wrc-Win64-ShippingDRM.exe`. Breakpoints in `main.cpp` work; the symbols are in `build\Debug\main.pdb`.
When the game closes without a word, `python wcmods.py cpp crash` in wcmods reads its last crash and says
whether this mod was on the stack, and where.

**wcmods' own build does the same:** `python wcmods.py cpp build <the mod's folder>` (or its id, in `mods/`)
builds the mod with CMake and Ninja into the same `dlls\main.dll`, as Clan Mod Studio's Build C++ button
does. The solution and `cpp\CMakeLists.txt` are two ways to build one mod; keep their source lists the same.

## How the solution builds it

The project compiles `cpp\src\*.cpp` with the flags UE4SS's own build uses (C++latest, `/MD`, `/permissive-`,
`/Zc:preprocessor`, `/utf-8`...) and the defines UE4SS gives every mod, and links the UE4SS libraries wcmods
built in `cache\cpp\out\Game__Shipping__Win64\lib`. `UE4SS.props` holds the parts that depend on the UE4SS
version: include folders, defines, libraries, the UE4SS commit (for `build.json`) and the compiler version
that built UE4SS. UE4SS's libraries are whole-program optimised, so the mod must link with that very
compiler version; the project pins it (`VCToolsVersion`). Both configurations link the same shipping UE4SS;
a `Debug` build only turns optimisation off for the mod's code.

Before compiling, the project checks that wcmods is where `wcmods.props` says, that `UE4SS.props` has been
written, and that UE4SS is built, and says what to do if not. After linking, it writes `dlls\build.json`: an
install compares the UE4SS named there with the game's and leaves out a DLL built for another, since that can
crash the game.

**When something's off:**

- *"wcmods isn't at ..."*: set `WCModsRoot` (step 2).
- *"UE4SS.props isn't here yet"*: run the sync script (step 3), then reopen the solution.
- *"UE4SS.props is here, but this build didn't read it"*: close and reopen the solution.
- *"UE4SS isn't built in ..."*: run `cpp setup` and `cpp build` in wcmods (What it needs, step 3), then the
  sync script.
- *The toolset version isn't found*, or *C1047 (object created by a different compiler)*: Visual Studio
  updated since UE4SS was built. In wcmods, delete `cache\cpp\out`, run `cpp build tests/cpp-sdk` again, then
  the sync script here.
- *wcmods leaves the mod out: "built for UE4SS ... and the game has ..."*: UE4SS changed. `cpp setup`, `cpp
  build`, the sync script, and build again.
- *Red squiggles but it builds*: the IntelliSense folders come from `UE4SS.props`; run the sync script and
  reopen the solution.

## Sharing it

Zip the folder (Clan Mod Studio's "Save as .zip" on the mod, or `python wcmods.py pack <id>`) and give it
out; players add the .zip in the studio. First take out what is yours alone, since a zip carries everything
in the folder: the build folders (`build\`, `.vs\`), `UE4SS.props` (it pins your compiler version; each
computer writes its own with the sync script) and a `wcmods.local.props`. Or share from git, where
`.gitignore` leaves all of those out. Players who don't build need the DLL: take `dlls/` out of
`.gitignore` to ship `dlls\main.dll` and `dlls\build.json` with the source. A mod built here runs only with
the UE4SS version it was built for, and players have the Visual C++ runtime for it from the Visual C++
Redistributable, which most do.
