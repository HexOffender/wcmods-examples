// Example studio page shipped by a mod. It edits the mod's own faster-run.json
// (declared in mod.json "studio_files") using the shared library passed in as `wc`.
// This mod's folder name, from where the studio serves this file (/mods/<id>/studio/section.js), so a copy
// under another name edits its own file.
const MOD = decodeURIComponent(new URL(import.meta.url).pathname.split("/")[2]);
const FILE = "faster-run.json";

export default {
  title: "Faster movement",
  async mount(root, wc) {
    const { el, api, toast } = wc;
    let data = { run: 1.25, walk: 1 };
    const r = await api.get(`/mods/${encodeURIComponent(MOD)}/file/${FILE}`);
    if (r.exists) data = JSON.parse(r.text);

    // The same range section.py accepts, 0.5 to 3 times the game's speed.
    const slider = (key, label) => {
      const value = el("strong", { text: `×${data[key]}` });
      const input = el("input", { type: "range", id: `fr-${key}`, min: "0.5", max: "3", step: "0.05", value: data[key] });
      input.addEventListener("input", () => { data[key] = Number(input.value); value.textContent = `×${data[key]}`; });
      return el("div", { class: "field" }, el("label", { for: `fr-${key}` }, `${label} `, value), input);
    };

    root.append(
      el("div", { class: "section-head" },
        el("span", { class: "eyebrow", text: "From the Faster Movement mod" }),
        el("h1", { text: "Faster movement" }),
        el("p", { class: "note", text: "Scales the cat's walking and running speed. This page and its build step come from the mod itself, built on the studio's shared library." })),
      el("div", { class: "card" },
        slider("run", "Running speed"),
        slider("walk", "Walking speed"),
        el("div", { class: "row" }, el("button", {
          class: "btn primary", text: "Save",
          onclick: async () => {
            try {
              await api.put(`/mods/${encodeURIComponent(MOD)}/file/${FILE}`, { text: JSON.stringify(data, null, 2) });
              toast("Saved. Install mods to apply it.");
            } catch (e) { toast(e.message, "bad"); }
          },
        }))));
  },
};
