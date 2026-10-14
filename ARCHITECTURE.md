# Architecture & File Map

| Subsystem / Domain | Root Path | Entry Point / Core Files |
| :--- | :--- | :--- |
| Library entry | `src/` | `init.lua` |
| Instance factory & theme registry | `src/` | `Creator.lua` |
| Icon catalog | `src/` | `Icons.lua` |
| Structural components | `src/Components/` | `Window.lua`, `Tab.lua`, `Section.lua`, `FloatingNav.lua`, `SearchBar.lua`, `EdgeSidebar.lua`, `Dashboard.lua`, `LoadingScreen.lua`, `Notification.lua`, `Dialog.lua`, `Tooltip.lua`, `Acrylic.lua` |
| Interactive elements | `src/Elements/` | `Button.lua`, `Toggle.lua`, `Slider.lua`, `Dropdown.lua`, `Colorpicker.lua`, `Keybind.lua`, `Input.lua`, `Paragraph.lua`, `Divider.lua` |
| Theme palettes | `src/Themes/` | `Manager.lua`, `Dark.lua`, `Ocean.lua`, `Abyss.lua`, `Light.lua` |
| Utility primitives | `src/Utils/` | `Signal.lua`, `Maid.lua`, `SafeParent.lua`, `Tween.lua`, `Spring.lua`, `Drag.lua` |
| Companion addons | `addons/` | `AnimationsManager.lua`, `SoundFXManager.lua`, `ConfigManager.lua`, `SaveManager.lua`, `InterfaceManager.lua` |
| Examples | `examples/` | `Example.lua` |
| Engineering docs | `docs/` | `ARCHITECTURE.md` |
| Build config | `/` | `default.project.json` (Rojo), `.darklua.json` (bundle) |

## Directory Responsibilities

- `src/init.lua`: Thin orchestrator — `Library:CreateWindow()` with Loading/Search config, `Library:SetTheme()`, `Library:RegisterTheme()`, `Library.Flags`, `Library.Themes`; registers `getgenv().FloodLibrary`.
- `src/Creator.lua`: Centralized `Instance.new` wrapper mapping properties to semantic theme tokens; holds `Creator.Registry` for theme switching.
- `src/Icons.lua`: Lucide icon catalog and image asset mapper.
- `src/Components/Window.lua`: Main window shell — creates ScreenGui via SafeParent, MainFrame, TopBar, ContentContainer, FloatingNav, optional SearchBar, EdgeSidebar, optional LoadingScreen. Drag attached to TopBar with offset-preserving Drag.Attach(). `AddTab()`, `AddQuickAction()`, `DismissLoading()`, `ToggleMinimize()`, `Destroy()`.
- `src/Components/Tab.lua`: Tab page only — dual-column ScrollingFrame grid. No rail button (FloatingNav owns navigation). `AddSection()`, `SetVisible()`.
- `src/Components/Section.lua`: Card panel with UIListLayout; all `AddX()` element methods delegate to Elements modules.
- `src/Components/FloatingNav.lua`: Glass panel left of MainFrame, spring-connected (freq=18, damp=0.80). Icon-stacked-above-label buttons with ActiveBar indicator. `AddEntry()`, `SelectById()`, `Follow(x, y, height)`, `SetVisible()`, `Destroy()`.
- `src/Components/SearchBar.lua`: Glass bar below MainFrame, spring-following. TextBox input searching registered elements. `RegisterElement()`, `Follow(x, y, width)`, `SetVisible()`, `Destroy()`.
- `src/Components/EdgeSidebar.lua`: Slim 40px clipper over 48px inner panel — ClipsDescendants hides left rounded corners. Spring-animated X slide. Mandatory restore button at top. `AddEntry()`, `OnRestore()`, `Show()`, `Hide()`, `Destroy()`.
- `src/Components/Dashboard.lua`: First page shown — async avatar thumbnail + DisplayName welcome header + developer-extensible ScrollingFrame content area. `GetPage()`, `GetContentArea()`.
- `src/Components/LoadingScreen.lua`: Full-screen overlay with animated 3-dot indicator and blue haze. AnimationsManager-independent. `SetStatus(text)`, `Dismiss()`.
- `src/Elements/`: Interactive controls — buttons, toggles, sliders, dropdowns, color pickers, keybinds, text inputs, paragraphs, dividers.
- `src/Themes/`: Four unified-schema palettes (`Ocean`, `Dark`, `Abyss`, `Light`) and `Manager.lua`.
- `src/Utils/Drag.lua`: Reliable drag — captures pointer offset on InputBegan, updates via UserInputService.InputChanged (global, never drops). `Drag.Attach(handle, target, onMove?) -> Handle`.
- `src/Utils/`: Signal, Maid, SafeParent (executor-safe GUI parenting), Spring physics, Tween helpers.
- `addons/AnimationsManager.lua`: Optional TweenService wrapper — pool-tracked tweens, `CancelAll()`. Never a core dependency.
- `addons/SoundFXManager.lua`: Optional per-sound pool playback with enable/volume control.
- `addons/ConfigManager.lua`: Optional JSON config I/O via readfile/writefile with schema registration and flag persistence.
- `addons/SaveManager.lua`, `addons/InterfaceManager.lua`: Legacy companion addons kept for compatibility.
- `examples/`: Full demonstration scripts used as integration test harnesses.
- `ctx/`: AI operational context — rules, workflows, domain notes.
