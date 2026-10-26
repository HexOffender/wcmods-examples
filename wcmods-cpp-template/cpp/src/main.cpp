// The template C++ mod. It keeps your cat's stamina full while settings.json's "full_stamina" is on, heals your
// cat on F7, says hello in the log when your cat appears, and has a page of its own in the mod menu (Insert).
//
// WCMods.hpp is wcmods' C++ SDK on top of UE4SS's own API; docs/SDK.md in wcmods, "C++ mods", documents every
// call. Everything that reaches into the game gives nullptr, nullopt, false or an empty Resource when what it asks
// for isn't there (no cat in a menu, say), so a check is one `if`. Everything here that touches the game runs on
// the game thread: inside a timer, a key, on_player, or the menu page's function.
//
// Build with the Visual Studio solution beside this folder, or `python wcmods.py cpp build <this folder>`; then
// put the mod in the game with wcmods (README.md).
#include <WCMods/WCMods.hpp>

#include <format>

namespace
{
    // settings.json's "full_stamina"; true when the key isn't there.
    auto full_stamina() -> bool { return wcmods::settings()["full_stamina"].boolean(true); }

    auto set_full_stamina(bool on) -> void { wcmods::settings().set("full_stamina", on); }
} // namespace

class TemplateMod : public wcmods::ModBase
{
  public:
    // UE4SS calls this once the engine is up: the place to set up timers, keys, hooks and menu pages.
    auto on_unreal_init() -> void override
    {
        wcmods::log(L"loaded (full stamina: {})", full_stamina());

        // Four times a second (looking up your cat goes through the game's objects, so not every frame).
        wcmods::every(0.25, [] {
            if (!full_stamina()) return;
            if (auto stamina = wcmods::cat().stamina()) *stamina.value = *stamina.max;
        });

        // F7 heals. The help text lists the key on the mod menu's Overview page.
        wcmods::on_key(wcmods::Key::F7, L"heal your cat", [] {
            if (wcmods::cat().heal()) wcmods::log(L"healed");
        });

        // When your cat appears (the forest loads), changes (a new area) or goes (menus: nullptr).
        wcmods::on_player([](wcmods::UObject* cat) {
            if (!cat) return;
            if (auto level = wcmods::Cat{cat}.level()) wcmods::log(L"your cat is here, level {}", *level);
        });

        // A mod with a settings.json gets a page of its settings in the mod menu without asking. The page below
        // covers this mod's one setting, so that page is turned off; take this line out to have both.
        wcmods::settings_page(false);

        // A page in the mod menu. The function draws its rows every frame while the page shows, on the game
        // thread; each row gives back what it holds, so a switch is read and written in one line.
        wcmods::menu_page(L"C++ Template", [](wcmods::Ui& ui) {
            ui.heading(L"C++ Template");
            ui.note(L"A C++ mod built from the template. F7 heals your cat.");
            set_full_stamina(ui.on_off(L"Full stamina", full_stamina()));
            if (auto stamina = wcmods::cat().stamina())
                ui.field(L"Stamina", std::format(L"{:.0f} / {:.0f}", *stamina.value, *stamina.max));
            if (ui.button(L"Save settings", L"primary") && wcmods::save_settings()) wcmods::log(L"settings saved");
        });
    }
};

// The two functions UE4SS calls in main.dll (start_mod, uninstall_mod): this ends the file.
WCMODS_MOD(TemplateMod)
