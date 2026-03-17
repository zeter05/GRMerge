# GRMerge

> A native macOS app for deep folder comparison — built with SwiftUI for Apple Silicon.

---

## What it does

GRMerge recursively compares two folder trees and shows you exactly what's different — file by file, folder by folder. It uses SHA-256 hashing for accurate content comparison and supports smart normalization rules so things like line endings or trailing whitespace don't clutter your diff.

---

## Features

### Core comparison
- **Deep recursive scan** — traverses the full directory tree on both sides
- **SHA-256 content hashing** — byte-accurate file comparison, not just size/date
- **Tree view results** — expandable folder structure with color-coded diff status
- **Empty folder detection** — distinguishes between truly empty folders and folders only present on one side

### Diff status
| Symbol | Meaning |
|--------|---------|
| `=` | Identical on both sides |
| `~` | Exists on both sides but content differs |
| `←` | Only in folder A |
| `→` | Only in folder B |

### Exclusion rules
Filter out noise before the comparison even starts:
- Exact file names (`.DS_Store`, `Thumbs.db`)
- File extensions (`*.log`, `*.tmp`)
- Directory names (`node_modules/`, `.git/`, `build/`)
- Glob patterns (`*.generated.swift`)

**Built-in presets** for Swift/Xcode, Node.js, and plain text projects.

### Normalization rules
Transform file content before hashing so cosmetic differences don't show up as changes:
- Ignore line endings (`\r\n` → `\n`)
- Ignore trailing whitespace
- Ignore all whitespace
- Ignore blank lines
- Ignore comments (`//` and `/* */`)
- Case-insensitive comparison

### UI
- **Breadcrumb path display** — full path broken into components with wrap, last segment highlighted
- **Filter bar** — show only modified / only-left / only-right / identical results
- **Collapsible sidebar sections** — rules and legend collapse to save space
- **Real-time scan progress** — per-phase progress bar with file counter and current file name
- **Results footer** — scan duration, total files scanned, folder count, size, and top file extensions summary

### Export
- Export results to **CSV** or **JSON** via native macOS save panel

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon (M1/M2/M3/M4/M5) or Intel
- Xcode 15+

---

## Getting started

```bash
git clone https://github.com/your-username/GRMerge.git
cd GRMerge
open GRMerge.xcodeproj
```

Press `⌘R` to build and run.

> **Note:** App Sandbox is disabled to allow access to arbitrary folders outside the standard sandboxed locations. This is intentional for a developer tool — do not re-enable it unless you plan to submit to the Mac App Store.

---

## Project structure

```
GRMerge/
├── GRMergeApp.swift              # App entry point (@main)
├── Models/
│   ├── FileNode.swift            # Core data model — represents a file or folder
│   ├── CompareStatus.swift       # Enum: identical / modified / onlyInLeft / onlyInRight
│   ├── CompareRule.swift         # ExcludeRule, NormalizeRule, RulePreset
│   └── ScanProgress.swift        # Progress reporting + ScanSummary stats
├── ViewModels/
│   └── CompareViewModel.swift    # App state, scan orchestration, filtering, export
├── Services/
│   ├── FileScanner.swift         # Recursive filesystem traversal with progress callbacks
│   └── FileComparator.swift      # Tree diffing + SHA-256 content comparison
└── Views/
    ├── ContentView.swift         # Root NavigationSplitView
    ├── SidebarView.swift         # Folder pickers, compare button, rules
    ├── FolderPickerRow.swift     # NSOpenPanel wrapper + PathBreadcrumb
    ├── RulesView.swift           # Exclude/normalize rule editor with presets
    ├── ResultsView.swift         # Tree list + filter bar + export menu
    ├── FileRowView.swift         # Single file/folder row with status badge
    ├── ScanProgressView.swift    # Per-phase animated progress during scan
    ├── ResultsFooterView.swift   # Stats bar + extension summary
    └── LegendView.swift          # Status icon legend
```

---

## Architecture

GRMerge follows the **MVVM** pattern native to SwiftUI:

```
View  ──(user action)──▶  ViewModel  ──(calls)──▶  Service
View  ◀──(@Published)───  ViewModel  ◀──(data)────  Service
```

- **Models** are plain Swift `struct`s — value types, no inheritance
- **`CompareViewModel`** is an `@MainActor ObservableObject` — all UI state lives here
- **Services** (`FileScanner`, `FileComparator`) are pure `struct`s with no state — easy to test
- Async work runs via `Task.detached(priority: .userInitiated)` to keep the main thread free
- Progress is reported back to the main actor via `Task { @MainActor in ... }` closures

---

## How the comparison works

```
1. Count total items (fast enumeration, no metadata)
        ↓
2. Scan folder A recursively
   → apply ExcludeRules at scan time (skip before loading)
   → emit ScanProgress every 50 files
        ↓
3. Scan folder B recursively (same)
        ↓
4. Diff the two trees
   → build name→node dictionaries for O(1) lookup
   → for each name: compare / onlyInLeft / onlyInRight
   → for file content: quick size check first, then SHA-256 on normalized content
   → for directories: recurse, mark parent modified if any child differs
        ↓
5. Publish results to UI
```

---

## Roadmap

- [ ] Lazy rendering for folders with 1000+ children
- [ ] Side-by-side file diff view (text files)
- [ ] Drag & drop folder selection
- [ ] Keyboard shortcuts
- [ ] Saved comparison sessions

