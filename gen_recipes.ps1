$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$inst    = 'D:\dj\dj2\.minecraft\versions\Enigmatica 6：Expert - E6E'
$modsDir = Join-Path $inst 'mods'
$bmJar   = Join-Path $modsDir 'BloodMagic-1.16.4-3.1.13-39.jar'
$jsFile  = Join-Path $inst 'kubejs\server_scripts\enigmatica\kubejs\expert\recipetypes\bloodmagic\alchemytable.js'
$rmFile  = Join-Path $inst 'kubejs\server_scripts\enigmatica\kubejs\expert\recipes\remove.js'
$head    = 'D:\mc\alchemytable-cc\_head.lua'
$tail    = 'D:\mc\alchemytable-cc\_tail.lua'
$outLua  = 'D:\mc\alchemytable-cc\alchemytable.lua'

function Add-Need($need, $key) {
    if ($need.ContainsKey($key)) { $need[$key] = $need[$key] + 1 } else { $need[$key] = 1 }
}

function Convert-InputList($inputArr, [ref]$nbt) {
    $need = @{}
    foreach ($el in $inputArr) {
        if ($el -is [System.Array]) {
            $ids = @()
            foreach ($sub in $el) {
                $names = $sub.PSObject.Properties.Name
                if ($names -contains 'nbt') { $nbt.Value = $true }
                if ($names -contains 'type' -and ("$($sub.type)" -like '*nbt*')) { $nbt.Value = $true }
                if ($names -contains 'item') { $ids += $sub.item }
                elseif ($names -contains 'tag') { $ids += ('#' + $sub.tag) }
            }
            if ($ids.Count -gt 0) { Add-Need $need ('|' + ($ids -join '|')) }
        }
        else {
            $names = $el.PSObject.Properties.Name
            if ($names -contains 'nbt') { $nbt.Value = $true }
            if ($names -contains 'type' -and ("$($el.type)" -like '*nbt*')) { $nbt.Value = $true }
            if ($names -contains 'item') { Add-Need $need $el.item }
            elseif ($names -contains 'tag') { Add-Need $need ('#' + $el.tag) }
        }
    }
    return $need
}

function Convert-JsInputs([string]$text, [ref]$nbt) {
    $items = New-Object System.Collections.ArrayList
    $depth = 0; $quote = ''; $cur = ''
    foreach ($ch in $text.ToCharArray()) {
        if ($quote -ne '') {
            $cur += $ch
            if ($ch -eq $quote) { $quote = '' }
            continue
        }
        if ($ch -eq "'" -or $ch -eq '"') { $quote = $ch; $cur += $ch; continue }
        if ($ch -eq '[') { $depth++; $cur += $ch; continue }
        if ($ch -eq ']') { $depth--; $cur += $ch; continue }
        if ($ch -eq ',' -and $depth -eq 0) { $items.Add($cur) | Out-Null; $cur = ''; continue }
        $cur += $ch
    }
    if ($cur.Trim() -ne '') { $items.Add($cur) | Out-Null }

    $need = @{}
    foreach ($it in $items) {
        $s = $it.Trim()
        if ($s.StartsWith('[')) {
            $inner = $s.TrimStart('[').TrimEnd(']')
            $ids = @()
            foreach ($part in $inner.Split(',')) {
                $p = $part.Trim()
                if ($p -eq '') { continue }
                if ($p -like 'Item.of*') {
                    $nbt.Value = $true
                    if ($p -match "Item\.of\(\s*'([^']+)'") { $ids += $matches[1] }
                }
                else { $ids += $p.Trim("'", '"') }
            }
            if ($ids.Count -gt 0) { Add-Need $need ('|' + ($ids -join '|')) }
        }
        elseif ($s -like 'Item.of*') {
            $nbt.Value = $true
            if ($s -match "Item\.of\(\s*'([^']+)'") { Add-Need $need $matches[1] }
        }
        else {
            Add-Need $need ($s.Trim("'", '"'))
        }
    }
    return $need
}

# ---------- 1) jar 里的原版配方 ----------
$recipes = [ordered]@{}
$z = [System.IO.Compression.ZipFile]::OpenRead($bmJar)
foreach ($e in $z.Entries) {
    if ($e.FullName -notlike 'data/bloodmagic/recipes/alchemytable/*.json') { continue }
    $sr = New-Object System.IO.StreamReader($e.Open()); $t = $sr.ReadToEnd(); $sr.Close()
    $j = $t | ConvertFrom-Json
    $id = 'bloodmagic:' + ($e.FullName -replace '^data/bloodmagic/recipes/', '' -replace '\.json$', '')
    $nbt = $false
    $need = Convert-InputList $j.input ([ref]$nbt)
    if ($need.Count -eq 0) { continue }
    $out = ''
    if ($j.output -and $j.output.item) { $out = "$($j.output.item)" }
    $recipes[$id] = [pscustomobject]@{ id = $id; out = $out; need = $need; nbt = $nbt }
}
$z.Dispose()
Write-Host ("[1] jar recipes: {0}" -f $recipes.Count)

# ---------- 2) E6E expert KubeJS ----------
$js = [System.IO.File]::ReadAllText($jsFile, [System.Text.Encoding]::UTF8)
$prefix = 'enigmatica:expert/bloodmagic/alchemytable/'
if ($js -match "id_prefix\s*=\s*'([^']+)'") { $prefix = $matches[1] }

$rx = [regex]"(?s)\{\s*inputs:\s*\[(.*?)\]\s*,\s*output:\s*'([^']+)'\s*,\s*count:\s*\d+\s*,\s*syphon:\s*\d+\s*,\s*ticks:\s*\d+\s*,\s*orbLevel:\s*\d+\s*,\s*id:\s*(?:'([^']*)'|``([^``]*)``)\s*\}"
$nJs = 0
foreach ($m in $rx.Matches($js)) {
    $idRaw = ''
    if ($m.Groups[3].Success) { $idRaw = $m.Groups[3].Value } else { $idRaw = $m.Groups[4].Value }
    $id = $idRaw.Replace('${id_prefix}', $prefix)
    $nbt = $false
    $need = Convert-JsInputs $m.Groups[1].Value ([ref]$nbt)
    if ($need.Count -eq 0) { continue }
    $recipes[$id] = [pscustomobject]@{ id = $id; out = "$($m.Groups[2].Value)"; need = $need; nbt = $nbt }
    $nJs++
}
Write-Host ("[2] kubejs expert recipes matched: {0}, total: {1}" -f $nJs, $recipes.Count)

# patchouli_safe_removals 里的 id 实际上被替换成废配方了，删掉
if ($js -match "(?s)patchouli_safe_removals\s*=\s*\[(.*?)\];") {
    foreach ($m2 in [regex]::Matches($matches[1], "id:\s*'([^']+)'")) {
        $rid = $m2.Groups[1].Value
        if ($recipes.Contains($rid)) { $recipes.Remove($rid) }
    }
}

# 涂抹油升级配方（JS 里用循环 push 的）
$anoints = @('holy_water_anointment', 'looting_anointment', 'melee_anointment', 'hidden_knowledge_anointment',
    'fortune_anointment', 'bow_power_anointment', 'smelting_anointment', 'silk_touch_anointment',
    'quick_draw_anointment', 'bow_velocity_anointment')
foreach ($a in $anoints) {
    $id = "bloodmagic:alchemytable/${a}_l"
    $recipes[$id] = [pscustomobject]@{ id = $id; out = "bloodmagic:${a}_l"; need = @{ "bloodmagic:$a" = 1; 'bloodmagic:tauoil' = 1 }; nbt = $false }
    if ($a -ne 'smelting_anointment' -and $a -ne 'silk_touch_anointment') {
        $id2 = "bloodmagic:alchemytable/${a}_2"
        $recipes[$id2] = [pscustomobject]@{ id = $id2; out = "bloodmagic:${a}_2"; need = @{ "bloodmagic:$a" = 1; 'bloodmagic:strong_tau' = 1 }; nbt = $false }
    }
}

# remove.js 里删掉的配方
if (Test-Path -LiteralPath $rmFile) {
    $rm = [System.IO.File]::ReadAllText($rmFile, [System.Text.Encoding]::UTF8)
    $nRm = 0
    foreach ($k in @($recipes.Keys)) {
        if ($rm.Contains($k)) { $recipes.Remove($k); $nRm++ }
    }
    Write-Host ("[3] removed by remove.js: {0}" -f $nRm)
}

# ---------- 3) 标签解析 ----------
$needed = @{}
foreach ($r in $recipes.Values) {
    foreach ($k in $r.need.Keys) {
        if ($k.StartsWith('#')) { $needed[$k.Substring(1)] = $true }
        elseif ($k.StartsWith('|')) {
            foreach ($id in $k.Substring(1).Split('|')) {
                if ($id.StartsWith('#')) { $needed[$id.Substring(1)] = $true }
            }
        }
    }
}
Write-Host ("[4] tags needed: {0} -> {1}" -f $needed.Count, (($needed.Keys | Sort-Object) -join ', '))

$tagDefs = @{}
$jarList = @(Get-ChildItem -LiteralPath $modsDir -Filter '*.jar' -ErrorAction SilentlyContinue)
$verRoot = Split-Path -Parent $inst
$jarList += @(Get-ChildItem -LiteralPath $verRoot -Recurse -Depth 1 -Filter '*.jar' -ErrorAction SilentlyContinue)
Write-Host ("[5] scanning {0} jars for item tags ..." -f $jarList.Count)
foreach ($jf in $jarList) {
    $zz = $null
    try { $zz = [System.IO.Compression.ZipFile]::OpenRead($jf.FullName) } catch { continue }
    foreach ($e in $zz.Entries) {
        $fn = $e.FullName
        if (-not $fn.StartsWith('data/')) { continue }
        if ($fn -notmatch '^data/([^/]+)/tags/items/(.+)\.json$') { continue }
        $tag = "$($matches[1]):$($matches[2])"
        if ($tagDefs.ContainsKey($tag)) { continue }
        $sr = New-Object System.IO.StreamReader($e.Open()); $t = $sr.ReadToEnd(); $sr.Close()
        $vals = @()
        try { $jj = $t | ConvertFrom-Json; if ($jj.values) { $vals = @($jj.values) } } catch { }
        $tagDefs[$tag] = $vals
    }
    $zz.Dispose()
}
Write-Host ("[6] tag definitions collected: {0}" -f $tagDefs.Count)

function Resolve-Tag([string]$tag, [hashtable]$seen) {
    $res = New-Object System.Collections.ArrayList
    if ($seen.ContainsKey($tag)) { return $res }
    $seen[$tag] = $true
    if ($tagDefs.ContainsKey($tag)) {
        foreach ($v in $tagDefs[$tag]) {
            $s = "$v"
            if ($s.StartsWith('#')) {
                foreach ($x in (Resolve-Tag $s.Substring(1) $seen)) { $res.Add($x) | Out-Null }
            }
            else { $res.Add($s) | Out-Null }
        }
    }
    return $res
}

$tagItems = @{}
foreach ($tag in $needed.Keys) {
    $items = @(Resolve-Tag $tag @{} | Sort-Object -Unique)
    if ($items.Count -gt 0) { $tagItems[$tag] = $items }
}
Write-Host ("[7] tags resolved: {0}" -f $tagItems.Count)
foreach ($tag in ($tagItems.Keys | Sort-Object)) {
    Write-Host ("    {0} = {1}" -f $tag, (($tagItems[$tag] | Select-Object -First 8) -join ', '))
}

# ---------- 4) 输出 Lua ----------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("-- ==== AUTO GENERATED: BloodMagic-1.16.4-3.1.13-39.jar + E6E expert kubejs ====")
[void]$sb.AppendLine("-- need = 配方里每种原料出现的次数（= 要占几个格子）; nbt=true 的条目脚本分不清 NBT，不参与自动匹配")
[void]$sb.AppendLine("local TAG_ITEMS = {")
foreach ($tag in ($tagItems.Keys | Sort-Object)) {
    $list = (($tagItems[$tag] | ForEach-Object { '["' + $_ + '"]=true' }) -join ', ')
    [void]$sb.AppendLine(("    [`"{0}`"] = {{ {1} }}," -f $tag, $list))
}
[void]$sb.AppendLine("}")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("local RECIPES = {")
$sorted = $recipes.Values | Sort-Object @{ Expression = { $_.need.Count }; Descending = $true }, id
foreach ($r in $sorted) {
    $parts = @()
    foreach ($k in ($r.need.Keys | Sort-Object)) { $parts += ('["' + $k + '"]=' + $r.need[$k]) }
    $nbtTag = ''
    if ($r.nbt) { $nbtTag = ', nbt=true' }
    [void]$sb.AppendLine(('{{ id="{0}", out="{1}", need={{ {2} }}{3} }},' -f $r.id, $r.out, ($parts -join ', '), $nbtTag))
}
[void]$sb.AppendLine("}")
[void]$sb.AppendLine("-- ==== AUTO GENERATED END ====")

$headText = [System.IO.File]::ReadAllText($head, [System.Text.Encoding]::UTF8)
$tailText = [System.IO.File]::ReadAllText($tail, [System.Text.Encoding]::UTF8)
$final = $headText.TrimEnd() + "`r`n" + $sb.ToString() + "`r`n" + $tailText
[System.IO.File]::WriteAllText($outLua, $final, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("[8] wrote {0} ({1} bytes), recipes = {2}" -f $outLua, (Get-Item -LiteralPath $outLua).Length, $sorted.Count)
Write-Host "--- sample lines ---"
Get-Content -LiteralPath $outLua | Select-String -Pattern 'tau_oil|weak_tau' | Select-Object -First 6
