# wcmods examples

Example mods for [wcmods](https://github.com/HexOffender/warrior-cats-mods), the mod manager for
*Warrior Cats: Clans of the Forest*, and its Clan Mod Studio. wcmods itself comes with one mod, the
in-game mod menu. These are separate mods: use them as they are, or start your own from one.

## Adding them

- **Clan Mod Studio:** download this repository (the green **Code** button, then **Download ZIP**)
  and drop the .zip on the studio's Mods page. It lists every mod in it; tick the ones you want and
  press **Add these**. Each one goes into your `mods` folder as your own copy, which you can change.
- **Command line:** `python wcmods.py add path/to/wcmods-examples/palette-dark-forest`, one folder
  at a time.

The ones that run code (Game Tweaks, Faster Movement, Quest Markers, Mistwhisker, The Moonlit Path
and the C++ Mod Template) stay off until you allow mods that run code (Options, on the Mods page).
Moonlit Herbs, Mistwhisker and The Moonlit Path need a wcmods from October 2026 or later
(`items.json`, and `Game.npcs` for cats of a mod's own). Most others need UE4SS, which the studio's
"Get set up" installs. The C++ Mod Template is source: it has to be built before it goes in the game
(its README says how), so it's one to copy and start from rather than add as it is.

## The examples

Each folder is one mod: its `mod.json`, and the files for its kind of change. How each kind of file
works is in wcmods' [README](https://github.com/HexOffender/warrior-cats-mods#file-formats) and
[docs/SDK.md](https://github.com/HexOffender/warrior-cats-mods/blob/main/docs/SDK.md).

### Looks (`palette.json`)

Ten themed palettes. Each recolours the game's coats and eyes, a whole-game restyle (pick one theme at
a time for those; the eye and coat mods go on top of a theme), and adds its 25 pattern and 25 marking
colours as new colours, each theme in slots of its own, so every theme can be on at once and all of
them are new choices. With the [Creator palettes](https://github.com/HexOffender/wcmods-creator-palettes)
mod they're in the cat maker's colour picker, a theme at a time; `cats.json` (Clan Mod Studio's Your
cat page) gives them to any cat in your save.

| Folder | What it does | New pattern and marking slots |
|---|---|---|
| `palette-thunderclan-forest` | Warm gingers and rich browns, moss and bracken extras, amber and leaf-green eyes | 100-124 |
| `palette-riverclan-waters` | Silvery, cool coats with river-blue greys, reed and kingfisher extras, teal and blue eyes | 125-149 |
| `palette-shadowclan-night` | Darker, smoky coats, marsh and nightshade extras, glowing yellow-green eyes | 150-174 |
| `palette-windclan-moor` | Sandy, weathered coats, heather and gorse extras, pale gold and hazel eyes | 175-199 |
| `palette-skyclan-sunset` | Glowing oranges and roses, sunset and twilight extras, fiery eyes | 200-224 |
| `palette-starclan-silverpelt` | Pale, frosted coats with a silver-blue sheen, starlight extras, eyes that glow from the pupil out | 225-249 |
| `palette-dark-forest` | Dim, ashen coats, rot and bone extras, blood-red and sickly eyes | 250-274 |
| `palette-leaf-bare-frost` | Wintry, icy coats, snow and holly extras, ice-blue eyes | 275-299 |
| `palette-pastel-kits` | Soft pastel coats and eyes, mint, lavender and blush extras | 300-324 |
| `palette-vivid-clans` | Saturated, storybook colours: bold coats, bright extras, vivid eyes | 325-349 |
| `gemstone-eyes` | The 20 standard iris colours as vivid jewel tones | |
| `starclan-glow-eyes` | Pale, luminous two-tone irises, a gradient example. Enable it instead of Gemstone Eyes, or give it a higher priority | |
| `richer-coats` | Deeper versions of the 15 natural coat colours | |

### Controls and camera (`controls.json`, `mouselook.json`)

| Folder | What it does |
|---|---|
| `example-controls` | Example key remaps (Interact on F, Scent tracking on Tab...) |
| `mouse-look` | Turn and tilt the camera with the mouse while exploring; F6 switches it off and on |

### Game data (`data.json` cell edits)

| Folder | What it does |
|---|---|
| `double-xp` | Doubles the experience every fight gives |
| `npc-size-variety` | A wider size range for newly generated Clan cats |

### New items (`items.json`)

| Folder | What it does |
|---|---|
| `moonlit-herbs` | A Moon Herb and a Starlight Pouch to barter for at the medicine cat, made with a new material, Moonstone, which the Moss Patch accessory now takes too, and a Moonlit Collar, a new look for the Dog Collar. Their icons and the collar's look are the game's own recoloured at install. Needs the Oodle DLL |

### In-game scripts (`scripts/main.lua`, with `settings.json`)

| Folder | What it does |
|---|---|
| `game-tweaks` | Live settings on its page in the mod menu: full stamina, hold the time of day, keep the fresh-kill pile up, heal on a key |
| `custom-npc` | Mistwhisker, a cat of your own: their own colours, a name over their head and lines to say when you talk to them (T, or up on the d-pad). The first time, they turn up beside you; F8 moves them |
| `moonlit-path` | A questline: Brindlemoon asks you to gather moss, visit your Clan's medicine cat and come back, for a reward. Steps on screen, a marker to follow, progress kept between sessions and a page in the mod menu |

### Build steps (`section.py`)

| Folder | What it does |
|---|---|
| `faster-run` | Scales walking and running speed, from its own build step and a studio page (`studio/section.js`) |
| `quest-markers` | A custom quest drawn on screen, markers on nearby pickups and a debug panel, from a UE4SS script the build step ships |

### C++ mods (`cpp/`, built into `dlls/main.dll`)

| Folder | What it does |
|---|---|
| `wcmods-cpp-template` | A starting point for a C++ mod on wcmods' C++ SDK, with a Visual Studio solution that builds and debugs it the way wcmods' `cpp build` does: full stamina while its setting is on, heal on F7, a page in the mod menu. Copy the folder, name it after your mod, run its sync script once, and build. Needs wcmods' `cpp setup` and `cpp build` run once (Visual Studio, Rust, git); its README has the steps |

## Game updates

A mod's `mod.json` can list the game builds it was made for (`"game_builds"`). These don't yet, so
wcmods treats them as made for build 24847281. After a game update it leaves them out until they're
updated here, or until you choose to use one anyway on that build.

## No game files

These mods change the game only through wcmods' own formats: palettes, `data.json` cell edits,
`items.json`, controls, scripts, and C++ on wcmods' SDK. None of them contains the game's files or code.

The palettes are generated from the game's colours by `tools/make_palettes.py` in wcmods, run on a
computer with the game:

```
python tools/make_palettes.py --out ../wcmods-examples
```
