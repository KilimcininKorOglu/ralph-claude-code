# Task-Based AI Selection

## Problem

Droid kodlama görevlerinde mükemmel çalışıyor ancak structured output gerektiren işlemlerde (PRD parsing, task addition) tutarsız davranıyor. Claude ise structured output'ta güvenilir ama kodlama için droid daha hızlı/ucuz olabilir.

## Solution

AI provider'ı görev tipine göre ayırma:
- **Planning AI**: PRD parsing, task addition, feature analysis
- **Coding AI**: Task execution, code generation, implementation

## Config Structure

```json
{
  "ai": {
    "planning": "claude",
    "coding": "droid",
    "timeout": 300,
    "prdTimeout": 1200,
    "maxRetries": 10
  }
}
```

### Fallback Behavior

- Eğer sadece `provider` tanımlıysa, her iki görev tipi için o kullanılır (backward compat)
- Eğer `planning` veya `coding` tanımlıysa, ilgili görev tipi için o kullanılır
- `auto` değeri için mevcut otomatik algılama kullanılır

## Affected Commands

| Command | AI Type | Config Key |
|---------|---------|------------|
| `hermes-prd` | Planning | `ai.planning` |
| `hermes-add` | Planning | `ai.planning` |
| `hermes -TaskMode` | Coding | `ai.coding` |
| `hermes -TaskStatus` | None | - |

## Implementation Steps

### 1. Update ConfigManager.ps1

```powershell
function Get-AIForTask {
    param(
        [ValidateSet("planning", "coding")]
        [string]$TaskType
    )
    
    # Check task-specific config first
    $specific = Get-ConfigValue -Key "ai.$TaskType"
    if ($specific -and $specific -ne "auto") {
        return $specific
    }
    
    # Fallback to general provider
    $general = Get-ConfigValue -Key "ai.provider"
    if ($general -and $general -ne "auto") {
        return $general
    }
    
    # Auto-detect
    return Get-AutoProvider
}
```

### 2. Update hermes-prd.ps1

```powershell
# Replace
$AI = Get-ConfigValue -Key "ai.provider"

# With
$AI = Get-AIForTask -TaskType "planning"
```

### 3. Update hermes-add.ps1

```powershell
# Replace
$AI = Get-ConfigValue -Key "ai.provider"

# With
$AI = Get-AIForTask -TaskType "planning"
```

### 4. Update hermes_loop.ps1

```powershell
# Replace
$AI = Get-ConfigValue -Key "ai.provider"

# With
$AI = Get-AIForTask -TaskType "coding"
```

### 5. Update setup.ps1 Template

Default config template'e yeni alanları ekle:

```json
{
  "ai": {
    "planning": "claude",
    "coding": "droid",
    "timeout": 300,
    "prdTimeout": 1200,
    "maxRetries": 10
  }
}
```

### 6. Update Global Config

```powershell
# install.ps1 - default global config
$defaultConfig = @{
    ai = @{
        planning = "claude"
        coding = "droid"
        timeout = 300
        prdTimeout = 1200
        maxRetries = 10
    }
    # ... rest
}
```

## CLI Override

Mevcut `-AI` flag'i her zaman override eder:

```powershell
# Planning için claude yerine droid kullan
hermes-prd docs/PRD.md -AI droid

# Coding için droid yerine claude kullan
hermes -TaskMode -AI claude
```

## Migration

Mevcut config'ler çalışmaya devam eder:
- `ai.provider` hala desteklenir
- Yeni `ai.planning` ve `ai.coding` opsiyoneldir
- Öncelik: CLI flag > task-specific > general provider > auto

## Testing

1. Unit test: `Get-AIForTask` fonksiyonu
2. Integration test: hermes-prd with planning AI
3. Integration test: hermes -TaskMode with coding AI
4. Backward compat: eski config dosyaları

## Estimated Effort

- ConfigManager.ps1: 30 min
- hermes-prd.ps1: 15 min
- hermes-add.ps1: 15 min
- hermes_loop.ps1: 15 min
- setup.ps1: 15 min
- install.ps1: 15 min
- Tests: 45 min
- **Total: ~2.5 hours**
