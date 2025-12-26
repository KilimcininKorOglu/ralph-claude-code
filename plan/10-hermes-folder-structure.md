# .hermes Folder Structure Migration

## Problem

Mevcut yapıda Hermes dosyaları proje kök dizininde dağınık duruyor. Kullanıcının kendi proje yapısıyla karışabiliyor.

## Solution

Tüm Hermes dosyalarını `.hermes/` klasörüne taşı. Proje kök dizini temiz kalsın.

## New Structure

```
project-name/
├── .git/
├── .gitignore
├── .hermes/                    # Tüm Hermes dosyaları burada
│   ├── config.json             # hermes.config.json -> config.json
│   ├── PROMPT.md               # AI prompt dosyası
│   ├── tasks/                  # Task dosyaları
│   │   └── .gitkeep
│   ├── logs/                   # Log dosyaları
│   │   └── .gitkeep
│   └── docs/                   # PRD ve dökümanlar
│       └── .gitkeep
└── README.md                   # Proje README (kök dizinde kalır)
```

## Removed

- `src/` klasörü oluşturulmayacak (kullanıcı kendi yapar)
- `examples/` klasörü kaldırıldı (gereksiz)

## File Changes

### 1. setup.ps1

```powershell
# Old
$directories = @("src", "examples", "logs", "docs\generated")
New-Item -ItemType Directory -Path "tasks" -Force

# New
$hermesDir = ".hermes"
New-Item -ItemType Directory -Path $hermesDir -Force
$directories = @(
    "$hermesDir\tasks",
    "$hermesDir\logs", 
    "$hermesDir\docs"
)

# Config path change
# Old: hermes.config.json
# New: .hermes/config.json

# PROMPT.md path change
# Old: PROMPT.md
# New: .hermes/PROMPT.md
```

### 2. ConfigManager.ps1

```powershell
function Get-ProjectConfigPath {
    # Old: Join-Path $BasePath "hermes.config.json"
    # New: Join-Path $BasePath ".hermes\config.json"
}
```

### 3. hermes_loop.ps1

```powershell
# Tasks directory
# Old: $config.paths.tasksDir = "tasks"
# New: $config.paths.tasksDir = ".hermes\tasks"

# Logs directory  
# Old: $config.paths.logsDir = "logs"
# New: $config.paths.logsDir = ".hermes\logs"

# PROMPT.md path
# Old: "PROMPT.md"
# New: ".hermes\PROMPT.md"
```

### 4. hermes-prd.ps1

```powershell
# Tasks output directory
# Old: tasks/
# New: .hermes/tasks/

# PRD input (docs klasörü artık .hermes içinde)
# Kullanıcı PRD'yi istediği yerde tutabilir, ama default:
# Old: docs/PRD.md
# New: .hermes/docs/PRD.md veya proje kökünden
```

### 5. lib/TaskReader.ps1

```powershell
# Tasks directory default
# Old: "tasks"
# New: ".hermes\tasks"
```

### 6. lib/TaskStatusUpdater.ps1

```powershell
# run-state.md path
# Old: tasks/run-state.md
# New: .hermes/tasks/run-state.md
```

### 7. lib/PromptInjector.ps1

```powershell
function Get-PromptPath {
    # Old: Join-Path $BasePath "PROMPT.md"
    # New: Join-Path $BasePath ".hermes\PROMPT.md"
}
```

### 8. lib/Logger.ps1

```powershell
# Log files path
# Old: logs/hermes-xxx.log
# New: .hermes/logs/hermes-xxx.log
```

### 9. lib/prompts/prd-parser.md

```markdown
# FILE markers
# Old: ### FILE: tasks/001-xxx.md
# New: ### FILE: .hermes/tasks/001-xxx.md
```

### 10. Default Config (ConfigManager.ps1)

```powershell
$script:DefaultConfig = @{
    paths = @{
        tasksDir = ".hermes\tasks"
        logsDir = ".hermes\logs"
        docsDir = ".hermes\docs"
    }
}
```

### 11. .gitignore Template

```
# Hermes folder (AI workspace - not tracked)
.hermes/
```

### 12. install.ps1

Global installation path unchanged (`$env:LOCALAPPDATA\Hermes\`), but default config paths updated.

## Affected Files Summary

| File | Changes |
|------|---------|
| setup.ps1 | Directory structure, config path, PROMPT.md path |
| lib/ConfigManager.ps1 | Project config path, default paths |
| lib/TaskReader.ps1 | Tasks directory default |
| lib/TaskStatusUpdater.ps1 | run-state.md path |
| lib/PromptInjector.ps1 | PROMPT.md path |
| lib/Logger.ps1 | Logs directory |
| lib/prompts/prd-parser.md | FILE markers path |
| hermes_loop.ps1 | All path references |
| hermes-prd.ps1 | Tasks output path |
| hermes-add.ps1 | Tasks output path |
| hermes_monitor.ps1 | Status file path |
| install.ps1 | Default config paths |
| templates/PROMPT.md | No change (content) |
| tests/unit/*.Tests.ps1 | Update test paths |

## Migration for Existing Projects

Kullanıcılar mevcut projelerini migrate etmek isterse:

```powershell
# Migration script (opsiyonel)
hermes-migrate

# Manual migration:
mkdir .hermes
mv tasks .hermes/
mv logs .hermes/
mv PROMPT.md .hermes/
mv hermes.config.json .hermes/config.json
# docs klasörü varsa
mv docs .hermes/
```

## Backward Compatibility

- Eski yapıdaki projeleri tespit et ve uyarı ver
- `hermes-migrate` komutu ile otomatik migration

## Estimated Effort

- setup.ps1: 30 min
- ConfigManager.ps1: 15 min
- TaskReader.ps1: 15 min
- TaskStatusUpdater.ps1: 10 min
- PromptInjector.ps1: 10 min
- Logger.ps1: 10 min
- prd-parser.md: 10 min
- hermes_loop.ps1: 20 min
- hermes-prd.ps1: 15 min
- hermes-add.ps1: 15 min
- hermes_monitor.ps1: 10 min
- install.ps1: 10 min
- Tests update: 45 min
- **Total: ~3.5 hours**
