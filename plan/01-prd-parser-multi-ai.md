# PRD Parser - Multi-AI CLI Destegi Plani

## Genel Bakis

Kullanicinin PRD dosyasini alip, sectigi AI CLI araciyla `tasks/` klasorune task-plan formatinda dosyalar olusturan bir sistem.

## Desteklenecek AI CLI Araclari

| Arac | Komut | Kurulum |
|------|-------|---------|
| Claude Code | `claude` | `npm install -g @anthropic-ai/claude-code` |
| Gemini CLI | `gemini` | `npm install -g @google/gemini-cli` |
| Droid CLI | `droid` | Factory AI |
| Aider | `aider` | `pip install aider-chat` |

## Kullanim

```powershell
# Varsayilan (claude)
ralph-prd docs/PRD.md

# AI secerek
ralph-prd docs/PRD.md -AI claude
ralph-prd docs/PRD.md -AI gemini
ralph-prd docs/PRD.md -AI droid
ralph-prd docs/PRD.md -AI aider

# Hangi AI'lar mevcut?
ralph-prd -List
```

## Nasil Calisir?

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   PRD.md    │────▶│   ralph-prd.ps1  │────▶│  tasks/*.md     │
└─────────────┘     └──────────────────┘     └─────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  AI CLI Sec   │
                    ├───────────────┤
                    │ • claude      │
                    │ • gemini      │
                    │ • droid       │
                    │ • aider       │
                    └───────────────┘
```

## Akis

```
1. PRD dosyasini oku
2. Prompt template'i yukle (lib/prompts/prd-parser.md)
3. Secilen AI CLI'yi cagir
4. AI ciktisini parse et
5. tasks/ klasorune dosyalari yaz
6. tasks-status.md olustur
```

## Dosya Yapisi

```
ralph-claude-code/
├── ralph-prd.ps1              # Ana script (YENI)
├── lib/
│   ├── AIProvider.ps1         # AI CLI abstraction (YENI)
│   └── prompts/
│       └── prd-parser.md      # PRD parse prompt (YENI)
```

## lib/AIProvider.ps1

Her AI CLI icin ortak interface:

```powershell
function Invoke-AICommand {
    param(
        [string]$Provider,  # claude, gemini, droid, aider
        [string]$Prompt,
        [string]$Context
    )
    
    switch ($Provider) {
        "claude" { 
            $Context | claude --print "$Prompt"
        }
        "gemini" { 
            $Context | gemini --prompt "$Prompt"
        }
        "droid" { 
            droid --prompt "$Prompt" --context $Context
        }
        "aider" {
            aider --message "$Prompt" --file $Context
        }
    }
}

function Test-AIAvailable {
    param([string]$Provider)
    # CLI'nin kurulu olup olmadigini kontrol et
}

function Get-AvailableAIs {
    # Sistemde mevcut AI CLI'lari listele
}
```

## lib/prompts/prd-parser.md

AI'ya gonderilecek prompt:

```markdown
# PRD Parser Instructions

Analyze the PRD below and create task files in task-plan format.

## Output Format

For each feature, output a markdown file with this structure:

### FILE: tasks/XXX-feature-name.md
` ` `markdown
# Feature X: [Name]

**Feature ID:** FXXX
**Status:** NOT_STARTED
...

### TXXX: Task Name
**Status:** NOT_STARTED
...
` ` `

## Rules
- Each feature gets unique FXXX ID
- Each task gets unique TXXX ID (continues across features)
- Break down into 0.5-5 day tasks
- Include dependencies
- Include success criteria

## PRD Content:
{PRD_CONTENT}
```

## ralph-prd.ps1 Parametreleri

```powershell
param(
    [string]$PrdFile,           # PRD dosya yolu
    [ValidateSet("claude", "gemini", "droid", "aider", "auto")]
    [string]$AI = "auto",       # auto = ilk bulunani kullan
    [switch]$List,              # Mevcut AI'lari listele
    [switch]$DryRun,            # Sadece goster, dosya olusturma
    [string]$OutputDir = "tasks"
)
```

## Cikti Ornegi

```powershell
PS> ralph-prd docs/PRD.md -AI claude

[INFO] Reading PRD: docs/PRD.md
[INFO] Using AI: claude
[INFO] Parsing PRD with Claude Code...

[OK] Created: tasks/001-user-registration.md (F001, T001-T005)
[OK] Created: tasks/002-password-reset.md (F002, T006-T008)
[OK] Created: tasks/003-email-verification.md (F003, T009-T011)
[OK] Created: tasks/tasks-status.md

Summary:
  Features: 3
  Tasks: 11
  Estimated: 8 days

Next: Run 'ralph -TaskMode -AutoBranch -AutoCommit' to start
```

## Uygulama Sirasi

1. `lib/AIProvider.ps1` - AI CLI abstraction
2. `lib/prompts/prd-parser.md` - Parse prompt template
3. `ralph-prd.ps1` - Ana script
4. `install.ps1` guncelle - ralph-prd komutunu ekle
5. Test ve dokumantasyon

## Sonraki Adimlar

Onay sonrasi uygulama:

### Faz 1: Core
- [ ] lib/AIProvider.ps1
- [ ] lib/prompts/prd-parser.md

### Faz 2: Ana Script
- [ ] ralph-prd.ps1

### Faz 3: Entegrasyon
- [ ] install.ps1 guncelleme
- [ ] README.md guncelleme

### Faz 4: Test
- [ ] Unit testler
- [ ] Integration testler
