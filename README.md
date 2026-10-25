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

The ones that run code (Game Tweaks, Faster Movement, Quest Markers, Mistwhisker and The Moonlit Path)
stay off until you allow mods that run code (Options, on the Mods page). Moonlit Herbs, Mistwhisker and The Moonlit Path
need a wcmods from October 2026 or later (`items.json`, and `Game.npcs` for cats of a mod's own). Most others need UE4SS, which the studio's "Get set
up" installs.

## The examples

| Folder | What it does |
|---|---|
| `palette-thunderclan-forest`, `palette-riverclan-waters`, `palette-shadowclan-night`, `palette-windclan-moor`, `palette-skyclan-sunset`, `palette-starclan-silverpelt`, `palette-dark-forest`, `palette-leaf-bare-frost`, `palette-pastel-kits`, `palette-vivid-clans` | Ten themed palettes: coats, patterns, markings and eyes. Pick one theme at a time |
| `gemstone-eyes`, `starclan-glow-eyes` | New iris colours, on top of a theme |
| `richer-coats` | Deeper versions of the 15 natural coat colours |
| `mouse-look` | Turn and tilt the camera with the mouse while exploring; F6 switches it off and on |
| `example-controls` | Example key remaps (Interact on F, Scent tracking on Tab...) |
| `double-xp` | Doubles the experience every fight gives |
| `npc-size-variety` | A wider size range for newly generated Clan cats (`data.json` cell edits) |
| `moonlit-herbs` | New items (`items.json`): a Moon Herb and a Starlight Pouch to barter for at the medicine cat, made with a new material, Moonstone, which the Moss Patch accessory now takes too, and a Moonlit Collar, a new look for the Dog Collar. Their icons and the collar's look are the game's own recoloured at install. Needs the Oodle DLL and a wcmods with `items.json` |
| `game-tweaks` | An in-game script with live settings on its page in the mod menu: full stamina, hold the time of day, keep the fresh-kill pile up, heal on a key |
| `faster-run` | A mod with its own build step (`section.py`) and studio page (`studio/section.js`) |
| `quest-markers` | A custom quest drawn on screen, markers on nearby pickups and a debug panel |
| `custom-npc` | Mistwhisker, a cat of your own: their own colours, a name over their head and lines to say when you talk to them (T, or up on the d-pad). The first time, they turn up beside you; F8 moves them |
| `moonlit-path` | A questline: Brindlemoon asks you to gather moss, visit your Clan's medicine cat and come back, for a reward. Steps on screen, a marker to follow, progress kept between sessions and a page in the mod menu |

How each kind of file works is in wcmods'
[README](https://github.com/HexOffender/warrior-cats-mods#file-formats) and
[docs/SDK.md](https://github.com/HexOffender/warrior-cats-mods/blob/main/docs/SDK.md).

## Game updates

A mod's `mod.json` can list the game builds it was made for (`"game_builds"`). These don't yet, so
wcmods treats them as made for build 24847281. After a game update it leaves them out until they're
updated here, or until you choose to use one anyway on that build.

## No game files

These mods change the game only through wcmods' own formats: palettes, `data.json` cell edits,
`items.json`, controls and scripts. None of them contains the game's files or code.

The palettes are generated from the game's colours by `tools/make_palettes.py` in wcmods, run on a
computer with the game:

```
python tools/make_palettes.py --out ../wcmods-examples
```
