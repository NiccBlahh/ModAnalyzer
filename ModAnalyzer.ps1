# ============================================================
#   ModAnalyzer.ps1
#   made with love by @imnicc.dll  <3
#   love yall fr
# ============================================================

$banner = @"
                .,       '              ,  . .,  °             ,.  '                       .,       '                  ,. -,                           ,·'´¨;.  '                          , ·. ,.-·~·.,   '        ;'*`¨'`·-.,
              ;'   '·.,           ;'´    ,   ., _';\'         /   ';\                     ;'   '·.,               ,.·'´,    ,'\                          ;   ';:\           .·´¨';\         /  ·'´,.-·-.,   `,'          \`:·-,. ,   '` ·.
            .´  .-   ";\         \:´¨¯:;'   `;::'\:'\      ,'   ,'::'\                  .´  .-   ";\         ,·'´ .·´'´-·'´::::\'                       ;     ';:'\      .'´     ;:'\       /  .'´\:::::::'\   '\ °       \:/   ;\:'`:`·  '`·
           /   /:\:';   ;:'\         \::::;   ,'::_'\;'     ,'    ;:::';'                /   /:\:';   ;:'\      ;    ';:::\::\::;:'                        ;   ,  '·:;  .·´,.´';  ,'::;'    ,·'  ,'::::\:;:-·-:';  ';\         ;   ;'::\;::::`;   ;'\
         ,'  ,'::::'\';   ;::';           ,'  ,'::;'  '       ';   ,':::;'               ,'  ,'::::'\';   ;::';    \·.    `·;:'-·'´                          ;   ;'`.    ¨,.·´::;'  ;:::;    ;.   ';:::;´       ,'  ,':'\        ;  ,':::;  `·:;;   ,':\
     ,.-·'  '·~^*'´¨   ;::;`          ;  ;:::;  °       ;  ,':::;' '           ,.-·'  '·~^*'´¨   ;::;`    \:`·.   '`·,  '                          ;  ';::; \*´\:::::;  ,':::;'     ';   ;::;       ,'´ .'´\::';      ;   ;:::;     ,·' ,·':::;
     ':,  ,·:²*´¨¯'`;  ;::';           ;  ;::;'  '       ,'  ,'::;'              ':,  ,·:²*´¨¯'`;  ;::';       `·:'`·,   \'                          ';  ,'::;   \::\;:·';  ;:::; '     ';   ':;:   ,.·´,.·´::::\;'°     ;  ;:::;'  ,.'´,·´:::::;'
     ,'  / \:::::::::';   ;::;           ;  ;::;'          ;  ';_:,.-·´';\'       ,'  / \:::::::::';   ;::;        ,.'-:;'  ,·\                         ;  ';::;     '*´  ;',·':::;'        \·,   `*´,.·'´::::::;·´       ':,·:;::-·´,.·´\:::::;´'
    ,' ,'::::\·²*'´¨¯':,'\·;'           ',.'\::;'          ',   _,.-·'´:\:\'     ,' ,'::::\·²*'´¨¯':,'\·;'   ,·'´     ,.·´:::'\                        \´¨\::;          \¨\::::;          \\:¯::\:::::::;:·´           \::;. -·´::::::;\;·´'
    \`¨\::·/           \:·\'             \::\:;'          \¨:::::::::::\';     \`¨\::·/           \:·\'     \`*'´\::::::::;·''                        '\::\;            \:\;·'            `\:::::\;::·'´  °             \;'\:::::::::;·´'
     \'°\;'              \;'               \;:'      '       '\;::_;:-·'´'        \'°\;'              \;'       \::::\:;:·´                               '´¨               ¨'                  ¯                           `\;::-·´
      `¨''                '                  °                '¨                  `¨''                '          '`*'´'
"@

function Show-Banner {
    Clear-Host
    $colors = @('Cyan', 'Blue', 'Magenta', 'Cyan', 'Blue')
    $lines = $banner -split "`n"
    $i = 0
    foreach ($line in $lines) {
        Write-Host $line -ForegroundColor $colors[$i % $colors.Count]
        $i++
    }
    Write-Host ""
    Write-Host "         made with love by " -NoNewline -ForegroundColor DarkGray
    Write-Host "@imnicc.dll" -NoNewline -ForegroundColor Magenta
    Write-Host "   love yall " -NoNewline -ForegroundColor DarkGray
    Write-Host "<3" -ForegroundColor Red
    Write-Host ""
    Write-Host ("-" * 100) -ForegroundColor DarkGray
    Write-Host ""
}

function Get-ModInfo {
    param([string]$ModPath)

    $info = [ordered]@{
        Name        = Split-Path $ModPath -Leaf
        Path        = $ModPath
        Size        = $null
        Extension   = $null
        LastModified= $null
        IsDirectory = $false
        Files       = @()
        FileCount   = 0
    }

    if (Test-Path $ModPath -PathType Container) {
        $info.IsDirectory = $true
        $allFiles = Get-ChildItem -Recurse $ModPath -File -ErrorAction SilentlyContinue
        $info.Files = $allFiles
        $info.FileCount = $allFiles.Count
        $totalBytes = ($allFiles | Measure-Object -Property Length -Sum).Sum
        $info.Size = Format-Size $totalBytes
        $info.LastModified = (Get-Item $ModPath).LastWriteTime
        $info.Extension = "Folder"
    } elseif (Test-Path $ModPath -PathType Leaf) {
        $file = Get-Item $ModPath
        $info.Size = Format-Size $file.Length
        $info.Extension = $file.Extension.ToUpper()
        $info.LastModified = $file.LastWriteTime
        $info.FileCount = 1
    } else {
        return $null
    }

    return $info
}

function Format-Size {
    param([long]$Bytes)
    if ($null -eq $Bytes -or $Bytes -eq 0) { return "0 B" }
    $sizes = 'B','KB','MB','GB','TB'
    $order = 0
    $size = [double]$Bytes
    while ($size -ge 1024 -and $order -lt ($sizes.Count - 1)) {
        $order++
        $size /= 1024
    }
    return "{0:N2} {1}" -f $size, $sizes[$order]
}

function Analyze-ModContents {
    param($ModInfo)

    if (-not $ModInfo.IsDirectory -or $ModInfo.Files.Count -eq 0) { return }

    $extGroups = $ModInfo.Files | Group-Object Extension | Sort-Object Count -Descending
    $totalSize  = ($ModInfo.Files | Measure-Object -Property Length -Sum).Sum

    Write-Host "  [FILE TYPE BREAKDOWN]" -ForegroundColor Yellow
    Write-Host ""
    foreach ($g in $extGroups) {
        $ext  = if ($g.Name) { $g.Name.ToUpper() } else { "(no ext)" }
        $pct  = if ($totalSize -gt 0) { [math]::Round(($g.Group | Measure-Object Length -Sum).Sum / $totalSize * 100, 1) } else { 0 }
        $bar  = "#" * [math]::Round($pct / 2)
        $pad  = " " * (50 - $bar.Length)
        Write-Host ("    {0,-10} {1,4} file(s)  [{2}{3}] {4}%" -f $ext, $g.Count, $bar, $pad, $pct) -ForegroundColor Cyan
    }
    Write-Host ""
}

function Detect-ModType {
    param($ModInfo)

    if (-not $ModInfo.IsDirectory) {
        switch ($ModInfo.Extension) {
            ".JAR"   { return "Java Mod (JAR)" }
            ".ZIP"   { return "Archived Mod / Resource Pack" }
            ".RAR"   { return "Archived Mod (RAR)" }
            ".7Z"    { return "Archived Mod (7z)" }
            ".PK3"   { return "Quake/Doom Engine Mod" }
            ".PAK"   { return "Game PAK Archive" }
            ".VPAK"  { return "VPAK Package" }
            ".ESM"   { return "Bethesda Master Plugin (ESM)" }
            ".ESP"   { return "Bethesda Plugin (ESP)" }
            ".ESL"   { return "Bethesda Light Plugin (ESL)" }
            ".BA2"   { return "Bethesda Archive 2 (BA2)" }
            ".BSA"   { return "Bethesda Softworks Archive (BSA)" }
            ".PACKAGE" { return "The Sims Package" }
            ".SMOD"  { return "Factorio Mod (SMOD)" }
            ".WZ"    { return "Warzone 2100 Mod" }
            default  { return "Unknown / Generic Mod File" }
        }
    }

    # Folder-based detection
    $files = $ModInfo.Files.Name
    if ($files -match "manifest.json" -or $files -match "pack.mcmeta") { return "Minecraft Mod / Resource Pack" }
    if ($files -match "modinfo.json" -or $files -match "mod.json")      { return "Generic JSON-configured Mod" }
    if ($files -match ".*\.esp" -or $files -match ".*\.esm")            { return "Bethesda Game Mod Folder" }
    if ($files -match ".*\.jar")                                         { return "Java-based Mod Folder" }
    if ($files -match "info.json" -and $ModInfo.Path -match "factorio") { return "Factorio Mod Folder" }
    if ($files -match ".*\.lua")                                         { return "Lua-scripted Mod" }
    if ($files -match ".*\.py")                                          { return "Python-scripted Mod" }
    if ($files -match ".*\.dll")                                         { return "DLL-based Mod (Native)" }
    return "Unknown Mod Folder"
}

function Show-ModReport {
    param($ModInfo, [string]$ModType)

    Write-Host "  [MOD REPORT]" -ForegroundColor Green
    Write-Host ""
    Write-Host ("    Name         : {0}" -f $ModInfo.Name)         -ForegroundColor White
    Write-Host ("    Type         : {0}" -f $ModType)               -ForegroundColor Magenta
    Write-Host ("    Path         : {0}" -f $ModInfo.Path)          -ForegroundColor DarkGray
    Write-Host ("    Size         : {0}" -f $ModInfo.Size)          -ForegroundColor Cyan
    Write-Host ("    Last Modified: {0}" -f $ModInfo.LastModified)  -ForegroundColor DarkYellow
    Write-Host ("    Files        : {0}" -f $ModInfo.FileCount)     -ForegroundColor Cyan
    Write-Host ("    Is Directory : {0}" -f $ModInfo.IsDirectory)   -ForegroundColor DarkGray
    Write-Host ""

    Analyze-ModContents -ModInfo $ModInfo
}

function Start-ModAnalyzer {
    Show-Banner

    Write-Host "  Welcome to MOD ANALYZER" -ForegroundColor Cyan
    Write-Host "  Drag & drop a mod file or folder, or type a path below." -ForegroundColor DarkGray
    Write-Host ""

    while ($true) {
        Write-Host ("-" * 100) -ForegroundColor DarkGray
        Write-Host ""
        $input = Read-Host "  > Enter mod path (or 'q' to quit)"
        Write-Host ""

        if ($input -eq 'q' -or $input -eq 'quit' -or $input -eq 'exit') {
            Write-Host "  later! love you <3" -ForegroundColor Magenta
            Write-Host ""
            break
        }

        # Strip surrounding quotes (from drag & drop)
        $cleanPath = $input.Trim().Trim('"').Trim("'")

        if ([string]::IsNullOrWhiteSpace($cleanPath)) {
            Write-Host "  [!] No path entered." -ForegroundColor Red
            Write-Host ""
            continue
        }

        $modInfo = Get-ModInfo -ModPath $cleanPath

        if ($null -eq $modInfo) {
            Write-Host "  [!] Path not found: $cleanPath" -ForegroundColor Red
            Write-Host ""
            continue
        }

        $modType = Detect-ModType -ModInfo $modInfo
        Show-ModReport -ModInfo $modInfo -ModType $modType

        Write-Host ("-" * 100) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Analyze another mod? Press Enter to continue or 'q' to quit." -ForegroundColor DarkGray
        Write-Host ""
    }
}

# Entry point
Start-ModAnalyzer
