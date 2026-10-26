"""Example third-party section: scales the cat's walking and running speed.

It reads this mod's faster-run.json and turns it into TuningData edits through the shared library
(ctx.tune), so it merges with every other mod that edits TuningData.csv.
"""
from wcmods.sdk import Section

RUN = "Gameplay.Exploration.Player.MoveAndRun.Run.Speed"
WALK = "Gameplay.Exploration.Player.MoveAndRun.Walk.Speed"


class FasterMovement(Section):
    id = "faster-run"
    title = "Faster movement"
    files = ("faster-run.json",)

    def collect(self, mod, ctx):
        data = self.read_json(mod, "faster-run.json")
        for key in ("run", "walk"):
            value = data.get(key, 1)
            # bool is an int to Python: "run": true would otherwise pass, and reach the CSV as "xTrue".
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not 0.5 <= value <= 3:
                raise ValueError(f"faster-run.json: '{key}' should be a number from 0.5 to 3 (times the game's speed)")
        return data

    def build(self, ctx, items):
        for mod, data in items:
            ctx.tune({RUN: f"x{data.get('run', 1)}", WALK: f"x{data.get('walk', 1)}"}, source=mod.id)
            ctx.note("multipliers", data)
