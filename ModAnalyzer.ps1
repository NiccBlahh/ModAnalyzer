[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ensure required assemblies for GUI components are loaded
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Complete UI Structure (Embedding Your Requested Layout) ---
$htmlMarkup = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ModAnalyzer</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: #0e0c18;
  color: #c8c4f0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  border-bottom: 1px solid rgba(127,119,221,0.15);
}
.header-left { display: flex; align-items: center; gap: 10px; }
.logo-box {
  width: 28px; height: 28px;
  background: rgba(127,119,221,0.15);
  border: 1px solid rgba(127,119,221,0.3);
  border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
  font-size: 12px; font-weight: 600; color: #9d97e8;
}
.app-name { font-size: 13px; font-weight: 600; color: #c8c4f0; }
.app-ver  { font-size: 11px; color: rgba(168,164,220,0.4); margin-left: 2px; }
.header-right { display: flex; align-items: center; gap: 8px; }
.status-dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: #444;
  transition: background 0.3s;
}
.status-dot.scanning { background: #7f77dd; animation: blink 1s infinite; }
.status-dot.done      { background: #5dcaa5; }
.status-dot.warn      { background: #e24b4a; }
@keyframes blink { 50% { opacity: 0.3; } }
.status-label { font-size: 11px; color: rgba(168,164,220,0.5); }

.main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.controls {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 20px;
  border-bottom: 1px solid rgba(127,119,221,0.1);
}
.path-input {
  flex: 1;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(127,119,221,0.2);
  border-radius: 6px;
  color: #c8c4f0;
  font-family: inherit;
  font-size: 12px;
  padding: 8px 12px;
  outline: none;
  transition: border-color 0.2s;
}
.path-input:focus { border-color: rgba(127,119,221,0.5); }
.path-input::placeholder { color: rgba(168,164,220,0.3); }

.btn {
  background: #7f77dd;
  border: none;
  color: #fff;
  padding: 8px 16px;
  border-radius: 6px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}
.btn:hover { background: #6b62cb; }
.btn:disabled { background: #333; color: #777; cursor: not-allowed; }

.terminal-container {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  background: #090711;
  margin: 0 20px 20px 20px;
  border-radius: 8px;
  border: 1px solid rgba(127,119,221,0.08);
}
.log-entry { margin-bottom: 4px; white-space: pre-wrap; line-height: 1.5; }
.log-ok { color: #5dcaa5; }
.log-warn { color: #ffb86c; }
.log-danger { color: #e24b4a; font-weight: 600; }
.log-info { color: #8be9fd; }
.log-muted { color: rgba(168,164,220,0.4); }
</style>
</head>
<body>

<div class="header">
  <div class="header-left">
    <div class="logo-box">M</div>
    <div>
      <span class="app-name">Mecz Mod Analyzer</span>
      <span class="app-ver">Lite UI</span>
    </div>
  </div>
  <div class="header-right">
    <div id="statusDot" class="status-dot"></div>
    <div id="statusLabel" class="status-label">Idle</div>
  </div>
</div>

<div class="main">
  <div class="controls">
    <input type="text" id="pathInput" class="path-input" placeholder="Searching for Minecraft directories...">
    <button id="scanBtn" class="btn" onclick="window.external.TriggerScan(document.getElementById('pathInput').value)">Scan Directory</button>
  </div>
  
  <div class="terminal-container" id="terminal">
    <div class="log-entry log-muted">Initializing analyzer engine components... Ready.</div>
  </div>
</div>

<script>
  var term = document.getElementById('terminal');
  var dot = document.getElementById('statusDot');
  var lbl = document.getElementById('statusLabel');
  var btn = document.getElementById('scanBtn');

  function setStatus(state, text) {
    dot.className = "status-dot " + state;
    lbl.innerText = text;
    if(state === 'scanning') { btn.disabled = true; } else { btn.disabled = false; }
  }
  function clearLog() { term.innerHTML = ''; }
  function log(text, styleClass) {
    var div = document.createElement('div');
    div.className = 'log-entry ' + (styleClass || '');
    div.innerText = text;
    term.appendChild(div);
    term.scrollTop = term.scrollHeight;
  }
  function setPath(p) { document.getElementById('pathInput').value = p; }
</script>

</body>
</html>
'@

# --- Unified Scanning Helper ---
# A global variable is used here so it can be cleanly fetched inside the UI interop class
$Global:SuspiciousPatternsList = @("AimAssist","AutoAnchor","AutoCrystal","AutoTotem","JumpReset","VelocitySpoof","GrimVelocity","KillAura","TriggerBot","CheatBreaker","WalksyOptimizer","WalksyCrystalOptimizerMod","coord[-_ ]?mod")

function Resolve-GamePath {
    $defaultPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    if (Test-Path $defaultPath) {
        $files = Get-ChildItem $defaultPath -Filter *.jar -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) { return @{ Path = $defaultPath; Source = "Standard/Vanilla/Modrinth" } }
    }
    $featherBase = "$env:APPDATA\.feather\profiles"
    if (Test-Path $featherBase) {
        $latestProfile = Get-ChildItem $featherBase -Directory -ErrorAction SilentlyContinue | 
                         Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestProfile) {
            $featherMods = Join-Path $latestProfile.FullName "mods"
            if (Test-Path $featherMods) { return @{ Path = $featherMods; Source = "Feather Client" } }
        }
    }
    return @{ Path = $defaultPath; Source = "Default Context" }
}

function Get-FileSHA1 { param([string]$Path) return (Get-FileHash -Path $Path -Algorithm SHA1 -ErrorAction SilentlyContinue).Hash }

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch {}
    return @{ Name = ""; Slug = "" }
}

# --- UI Interop Bridge Class ---
[PermissionSet([Security.Permissions.SecurityAction]::Demand, Name="FullTrust")]
[System.Runtime.InteropServices.ComVisible($true)]
public class WebBridge {
    hidden [System.Windows.Forms.WebBrowser] $browser
    
    WebBridge([System.Windows.Forms.WebBrowser]$b) {
        $this.browser = $b
    }

    public void TriggerScan(string targetedPath) {
        if ([string]::IsNullOrWhiteSpace(targetedPath) -or -not (Test-Path $targetedPath -PathType Container)) {
            $this.InvokeUI("setStatus", @("warn", "Directory Invalid"))
            $this.InvokeUI("log", @("Error: The directory path specified does not exist.", "log-danger"))
            return
        }

        $this.InvokeUI("setStatus", @("scanning", "Analyzing Content"))
        $this.InvokeUI("clearLog", $null)
        $this.InvokeUI("log", @("Scanning path: $targetedPath...", "log-info"))

        try {
            $jarFiles = Get-ChildItem -Path $targetedPath -Filter *.jar -Force
        } catch {
            $this.InvokeUI("log", @("Error scanning folder: $($_.Exception.Message)", "log-danger"))
            $this.InvokeUI("setStatus", @("warn", "Execution Error"))
            return
        }

        if ($jarFiles.Count -eq 0) {
            $this.InvokeUI("log", @("Scan finished: Zero (.jar) modification configurations found.", "log-warn"))
            $this.InvokeUI("setStatus", @("done", "Finished"))
            return
        }

        $this.InvokeUI("log", @("Found $($jarFiles.Count) file(s). Cross-referencing signatures...", "log-muted"))

        $verifiedCount = 0
        $suspCount = 0
        $unknownCount = 0

        foreach ($jar in $jarFiles) {
            # Keeps the UI responsive and processing logs progressively
            [System.Windows.Forms.Application]::DoEvents() 
            
            # 1. Check Hash against Modrinth API
            $hash = Get-FileSHA1 -Path $jar.FullName
            if ($hash) {
                $modrinthData = Query-Modrinth -Hash $hash
                if ($modrinthData.Slug) {
                    $this.InvokeUI("log", @("[OK] Verified (Modrinth): $($modrinthData.Name) ($($jar.Name))", "log-ok"))
                    $verifiedCount++
                    continue
                }
            }
            
            # 2. Run Heuristic Checklist matching
            $matchedArray = New-Object System.Collections.Generic.List[string]
            foreach ($pattern in $Global:SuspiciousPatternsList) {
                if ($jar.Name -match $pattern) { $null = $matchedArray.Add($pattern) }
            }

            if ($matchedArray.Count -gt 0) {
                $this.InvokeUI("log", @("[!] SUSPICIOUS: $($jar.Name) -> Matched criteria: $($matchedArray -join ', ')", "log-danger"))
                $suspCount++
            } else {
                $this.InvokeUI("log", @("[?] UNKNOWN: $($jar.Name) (Unverified custom layout or client)", "log-warn"))
                $unknownCount++
            }
        }

        # Finish Report formatting output strings
        $this.InvokeUI("log", @("`n" + ("="*40) + "`nSCAN COMPLETE SUMMARY`n" + ("="*40), "log-info"))
        $this.InvokeUI("log", @("Verified Secure Mods: $verifiedCount", "log-ok"))
        $this.InvokeUI("log", @("Flagged Suspicious Items: $suspCount", "log-danger"))
        $this.InvokeUI("log", @("Unknown/Custom Mods: $unknownCount", "log-warn"))
        
        if ($suspCount -gt 0) {
            $this.InvokeUI("setStatus", @("warn", "Flags Tripped"))
        } else {
            $this.InvokeUI("setStatus", @("done", "Scan Clean"))
        }
    }

    private void InvokeUI(string functionName, object[] args) {
        if ($this.browser.Document) {
            $this.browser.Document.InvokeScript($functionName, $args) | Out-Null
        }
    }
}

# --- GUI Form Formatter Initialization ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mecz Mod Analyzer"
$form.Width = 800
$form.Height = 600
$form.StartPosition = "CenterScreen"

$webBrowser = New-Object System.Windows.Forms.WebBrowser
$webBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
$webBrowser.IsWebBrowserContextMenuEnabled = $false
$webBrowser.AllowWebBrowserDrop = $false
$webBrowser.ScriptErrorsSuppressed = $true

$form.Controls.Add($webBrowser)

# Bind Backend Object Bridge Interop to WebBrowser Execution Environment
$bridge = New-Object WebBridge ($webBrowser)
$webBrowser.ObjectForScripting = $bridge
$webBrowser.DocumentText = $htmlMarkup

# Run path auto-detection after the UI fully loads onto the screen
$form.Add_Shown({
    $detection = Resolve-GamePath
    $webBrowser.Document.InvokeScript("setPath", @($detection.Path)) | Out-Null
    $webBrowser.Document.InvokeScript("log", @("Auto-Detected Instance: $($detection.Source)", "log-info")) | Out-Null
})

[System.Windows.Forms.Application]::Run($form)
