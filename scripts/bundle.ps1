param([string]$Out = "dist\main.lua")

$root = Split-Path $PSScriptRoot -Parent

$order = @(
    "src\Utils\Signal.lua",
    "src\Utils\Maid.lua",
    "src\Utils\Spring.lua",
    "src\Utils\Tween.lua",
    "src\Utils\SafeParent.lua",
    "src\Utils\Drag.lua",
    "src\Themes\Ocean.lua",
    "src\Themes\Dark.lua",
    "src\Themes\Abyss.lua",
    "src\Themes\Light.lua",
    "src\Themes\Manager.lua",
    "src\Creator.lua",
    "src\Elements\Button.lua",
    "src\Elements\Toggle.lua",
    "src\Elements\Slider.lua",
    "src\Elements\Dropdown.lua",
    "src\Elements\Input.lua",
    "src\Elements\Keybind.lua",
    "src\Elements\Colorpicker.lua",
    "src\Elements\Paragraph.lua",
    "src\Elements\Divider.lua",
    "src\Components\Notification.lua",
    "src\Components\Section.lua",
    "src\Components\LoadingScreen.lua",
    "src\Components\FloatingNav.lua",
    "src\Components\SearchBar.lua",
    "src\Components\EdgeSidebar.lua",
    "src\Components\Dashboard.lua",
    "src\Components\Tab.lua",
    "src\Components\Window.lua",
    "src\init.lua"
)

$shim = @'
local __M = {}
local function __R(n)
    if __M[n] == nil then error("Flood: module not found: "..n,2) end
    if type(__M[n])=="function" then __M[n]=__M[n]() end
    return __M[n]
end
'@

$sb = [System.Text.StringBuilder]::new()
$sb.AppendLine("-- Flood UI Library") | Out-Null
$sb.AppendLine("-- https://github.com/ScriptB/flood-lib") | Out-Null
$sb.AppendLine($shim) | Out-Null

$requirePattern = [regex]'require\(script(?:\.\w+)*\.(\w+)\)'

foreach ($rel in $order) {
    $path = Join-Path $root $rel
    if (-not (Test-Path $path)) { Write-Warning "Skipping missing: $rel"; continue }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($rel)
    $raw  = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

    # Strip Luau directives
    $raw = $raw -replace '--!(?:strict|nonstrict|nocheck)\r?\n?', ''

    # Strip export type blocks (multiline, handles one level of nested braces)
    $raw = [regex]::Replace($raw, '(?s)export\s+type\s+\w+(?:<[^>]*>)?\s*=[^{]*\{(?:[^{}]|\{[^{}]*\})*\}', '')

    # Strip standalone type alias lines
    $raw = [regex]::Replace($raw, '(?m)^[ \t]*type\s+\w+[^\n]*$\r?\n?', '')

    # Strip generic type parameters from function definitions: function foo<T...>(
    $raw = [regex]::Replace($raw, '(function\s+[\w.:]+\s*)<[^>]*>', '$1')

    # Strip :: type cast expressions
    $raw = [regex]::Replace($raw, '\s*::\s*\w[\w.?<>\[\]| ]*', '')

    # Strip return type annotations after closing paren on function header line: ): Type
    $raw = [regex]::Replace($raw, '(\))\s*:\s*\w[\w.<>, ?|()]*(?=\s*\n|\s*$)', '$1')

    # Strip parameter/variable type annotations: name: Type (before , or ) only)
    $raw = [regex]::Replace($raw, '(\w)\s*:\s*((?:[\w.?]+(?:<[^>]*>)?|\([^)]*\)(?:\s*->\s*[\w.?<>()]+)?)(?:\s*[|&]\s*[\w.?]+(?:<[^>]*>)?)*)(?=\s*[,)])', '$1')

    # Strip table type annotations on parameters: param: { ... }? (single-line and multi-line)
    $raw = [regex]::Replace($raw, '(\w|\.\.\.)\s*:\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}\??(?=\s*[,)])', '$1')
    $raw = [regex]::Replace($raw, '(?s)(\w)\s*:\s*\{[\s\S]*?\}(?=\s*[\n,)])', '$1')

    # Strip variadic type annotations: ...: Type
    $raw = [regex]::Replace($raw, '\.\.\.\s*:\s*\w+', '...')

    # Strip typeof() type annotations: param: typeof(Expr)
    $raw = [regex]::Replace($raw, '(\w)\s*:\s*typeof\([^)]*\)', '$1')

    # Strip :: table type casts: :: { ... }
    $raw = [regex]::Replace($raw, '\s*::\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}', '')

    # Strip variable declaration type annotations: local x: Type = / local x: Type,
    $raw = [regex]::Replace($raw, '(local\s+\w+)\s*:\s*\w[\w.?<>\[\] |]*(?=\s*[=,\n])', '$1')

    # Strip return type annotations with table type: (): { ... }
    $raw = [regex]::Replace($raw, '(\))\s*:\s*\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}', '$1')

    $raw = $requirePattern.Replace($raw, '__R("$1")')

    $sb.AppendLine("__M[`"$name`"]=function()") | Out-Null
    $sb.Append($raw.TrimEnd()) | Out-Null
    $sb.AppendLine("`nend") | Out-Null
    $sb.AppendLine("") | Out-Null
}

$sb.AppendLine("return __R(`"init`")") | Out-Null

$outPath = Join-Path $root $Out
$outDir  = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
$sz = (Get-Item $outPath).Length
Write-Host ("Bundle: {0} KB" -f [int]($sz/1024))
