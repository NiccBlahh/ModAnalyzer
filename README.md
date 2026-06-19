# 🛡️ Atlas ModAnalyzer
> A PowerShell tool that scans your Minecraft mods for suspicious patterns, cheat clients, JVM injection, and unknown files.

---

## Installation

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/AtlasModAnalyzer/refs/heads/main/ModAnalyzer.ps1')"
```

Start Minecraft **first**, then run the script. It automatically detects your active instance via the Java process command line (`--gameDir`). Press **Enter** to confirm, or type a custom path instead.

---

## Output Labels

| Label | Meaning |
|-------|---------|
| ✅ VERIFIED | SHA-1 matched in an official database — safe |
| ❓ UNKNOWN | Not in any database, no suspicious content found |
| 🚨 SUSPICIOUS | Contains patterns or strings linked to cheat clients |
| 🟣 BYPASS / INJECTION | Structural anomalies — code injection, payload download, or data exfiltration detected |
| 🟡 OBFUSCATED | Not explicitly flagged, but heavily obfuscated — known obfuscator signatures or abnormal class naming |
| ⚡ JVM / RUNTIME INJECTION | Dangerous flags or external agents found in the live Java process |

---

## How It Works

### Phase 1 — SHA-1 Database Verification

A SHA-1 hash is computed for every `.jar` and checked against two databases:

**Modrinth API** `https://api.modrinth.com/v2/version_file/{hash}`
- Primary database of verified mods
- Returns project name and slug on match

**Megabase API** `https://megabase.vercel.app/api/query?hash={hash}`
- Fallback database if Modrinth returns nothing

Matched mods are immediately marked **VERIFIED** — no further analysis is performed on them.

---

### Phase 2 — Content & String Analysis

Unrecognized JARs are opened as zip archives. The following are extracted and scanned:

- Internal file names and directory paths
- Contents of `.json`, `.toml`, `.cfg`, `.properties` and `MANIFEST.MF`
- ASCII strings extracted from `.class` bytecode
- Hardcoded URLs embedded in config files
- `Runtime.exec()` and reflection calls
- Obfuscation indicators — `a/b/c/`-style paths, single-char class names, non-ASCII identifiers
- Nested JARs inside `META-INF/jars/` (scanned recursively)
- Fullwidth Unicode strings (e.g. `Ａｕｔｏ Ｃｒｙｓｔａｌ`) used to hide cheat labels from naive scanners

---

### Phase 3 — Bypass & Injection Detection

Structural analysis performed on every mod to detect dangerous or deceptive behavior:

| Check | Description |
|---|---|
| Suspicious nested JARs | Unknown dependencies bundled without version info |
| Hollow shell mods | Minimal outer classes wrapping a single inner JAR |
| `Runtime.exec()` | Arbitrary OS command execution capability |
| HTTP file download | Fetches and writes remote files to disk at runtime |
| HTTP POST exfiltration | Transmits system data (e.g. properties, tokens) to external servers |
| Heavy obfuscation | Statistically abnormal ratio of single-letter path segments |
| Numeric / Unicode class names | Automated obfuscator output patterns |
| Fake mod identity | Claims to be `sodium`, `lithium`, etc. but contains malicious code |

---

### Phase 4 — Obfuscation Analysis

Deep inspection of class naming conventions across the entire JAR:

| Flag | Description |
|---|---|
| Numeric class names | e.g. `1234.class` — typical of automated obfuscators |
| Unicode class names | Non-ASCII characters used as class identifiers |
| Fullwidth Unicode | `ａｂｃ` / `ＡＢＣ` / `０１２` style identifiers |
| Japanese obfuscation | Hiragana / Katakana class names (`じ.class`, `ふ.class`) |
| Short class names | High percentage of single or two-letter class names |
| Gibberish identifiers | Consonant clusters with no vowels |
| Confusion characters | Identifiers built from `I`, `l`, `1`, `O`, `0`, `_` |
| Single-char package paths | Deep nesting like `a/b/c/d/e/` |
| Known obfuscators | Skidfuscator, Paramorphism, Radon, Caesium, Bozar, Branchlock, Binscure, SuperBlaubeere27, Qprotect, Zelix, Stringer, JNIC, Scuti, Smoke |

---

### Phase 5 — JVM Argument Audit

If Minecraft is running when the script starts, the live Java process arguments are inspected for:

| Flag | Risk |
|---|---|
| `-javaagent:<path>` | External agent injected into the JVM — non-standard agents flagged |
| `-Xbootclasspath/p:` | Prepends to bootstrap classpath — can override core Java classes |
| `-Xbootclasspath/a:` | Appends below the classloader — used for deep injection |
| `-agentlib:jdwp` | JDWP debug agent active — allows remote debugging and control |
| `-agentpath:` | Native agent loaded — bypasses the Java sandbox entirely |

---

### Phase 6 — Download Source Tracking

Windows stores the origin URL of downloaded files in a hidden `Zone.Identifier` Alternate Data Stream. Atlas reads this stream for every mod and classifies the source:

| Source | Classification |
|---|---|
| Modrinth | ✅ Safe |
| CurseForge | ✅ Safe |
| GitHub | ⚠️ Verify |
| Discord / Discord CDN | ⚠️ Risky |
| MediaFire | ⚠️ Risky |
| MEGA | ⚠️ Risky |
| Dropbox | ⚠️ Risky |
| Google Drive | ⚠️ Risky |
| AnyDesk | 🚨 Suspicious |
| Known cheat client sites | 🚨 Suspicious |

---

## Detected Patterns

200+ patterns across multiple categories:

**Combat:**
`KillAura`, `AimAssist`, `AutoCrystal`, `CrystalAura`, `TriggerBot`, `SilentAim`, `Criticals`, `Reach`, `ReachHack`, `ShieldBreaker`, `BowAimbot`, `AutoCrit`, `AxeSpam`

**Crystal / Anchor / Bed:**
`AutoAnchor`, `AnchorTweaks`, `DoubleAnchor`, `AirAnchor`, `AutoBed`, `BedAura`, `NoBounce`, `SafeAnchor`

**Totem / Survival:**
`AutoTotem`, `HoverTotem`, `InventoryTotem`, `LegitTotem`, `AutoPot`, `AutoArmor`, `PopSwitch`, `MaceSwap`, `StunSlam`, `AutoDoubleHand`

**Movement:**
`FlyHack`, `SpeedHack`, `BHop`, `NoFall`, `NoKnockback`, `AntiKB`, `Phase`, `Scaffold`, `Timer`, `NoSlow`, `JumpReset`, `SprintReset`, `ElytraSpeed`, `WaterWalk`

**PvP Utility:**
`FakeLag`, `WTap`, `PingSpoof`, `FakeNick`, `PackSpoof`, `AutoGap`, `AutoPearl`, `AutoTPA`, `FakeInv`, `Antiknockback`

**Visual / ESP:**
`BlockESP`, `PlayerESP`, `XRayHack`, `Tracers`, `Freecam`, `FakeItem`, `NewChunks`, `FullBright`, `Wallhack`

**Automation:**
`FastPlace`, `ChestSteal`, `AutoClicker`, `AutoEat`, `AutoMine`, `AutoFirework`, `ElytraSwap`, `FastXP`, `AutoBridge`, `AutoBreach`

**Anti-Cheat Bypass:**
`GrimBypass`, `VulcanBypass`, `MatrixBypass`, `AACBypass`, `VerusDisabler`, `WatchdogBypass`, `PacketMine`, `PacketFly`

**Malware / RAT indicators:**
`TokenGrabber`, `SessionStealer`, `KeyLogger`, `Backdoor`, `ReverseShell`, `RemoteAccess`, webhook URLs, HWID checks

**Obfuscation libraries:**
`jnativehook`, `imgui.binding`, `imgui.gl3`, `imgui.glfw`, `chainlibs`, `Allatori`, `ZKM`, `Stringer`

**Suspicious mixins:**
`LicenseCheckMixin`, `KeyboardMixin`, `ClientPlayerInteractionManagerAccessor`, `ClientPlayerInteractionManagerMixin`

**Suspicious refmap files:**
`phantom-refmap.json`, `client-refmap.json`, `cheat-refmap.json`

**Known clients:**
`Wurst`, `Meteor`, `LiquidBounce`, `Sigma`, `Flux`, `Vape`, `Aristois`, `FutureClient`, `RusherHack`, `Asteria`, `Prestige`, `Xenon`, `Argon`, `Hellion`, `Donut`, `AstolfoClient`, `Novoclient`, `IntentClient`, `Pandaware`

Including fullwidth unicode variants of all the above (`Ａｕｔｏ Ｃｒｙｓｔａｌ`, `ＡｕｔｏＴｏｔｅｍ`, etc.)

---

## Changelog

### v1.0.0
- Initial release
- SHA-1 verification against Modrinth and Megabase
- Pattern and string analysis (200+ signatures)
- JVM argument audit
- Download source tracking via Zone.Identifier
- Obfuscation analysis with known obfuscator detection
- Bypass and injection structural scan

---

## Requirements

- Windows
- PowerShell 5.1 or higher
- Internet connection (for database lookups)

---

## Contact

Discord: `imnicc.dll`  
GitHub: [NiccBlahh](https://github.com/NiccBlahh)
