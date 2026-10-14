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

    $raw = $raw -replace '--!strict\r?\n?', ''
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
