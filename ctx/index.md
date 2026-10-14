# Context Router

| Intent | File |
| :--- | :--- |
| Code style & zero comments | ctx/rules/clean-code.md |
| Refactoring patterns | ctx/rules/micro-refactor.md |
| Workflows & task execution | ctx/workflows/task-execution.md |

## Component Ownership (2026-10-14 rewrite)

| Component | Owns |
| :--- | :--- |
| `Window.lua` | ScreenGui, MainFrame, TopBar, ContentContainer, FloatingNav instance, SearchBar instance, EdgeSidebar instance, LoadingScreen instance |
| `FloatingNav.lua` | Separate glass panel left of MainFrame; spring X/Y follows via `Follow()`; owns all nav button frames |
| `Tab.lua` | Page frame only inside ContentContainer; dual-column grid; no rail button |
| `Dashboard.lua` | First-page avatar+welcome frame; `GetContentArea()` for developer sections |
| `SearchBar.lua` | Glass bar below MainFrame; element registry; results dropdown |
| `EdgeSidebar.lua` | 40px clipper / 48px inner panel; restore button; icon action buttons |
| `LoadingScreen.lua` | Full-screen overlay; dot animation; `SetStatus()` / `Dismiss()` |
| `Drag.lua` | Global pointer-offset drag; never loses control on cursor leave |
