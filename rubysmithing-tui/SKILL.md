---
name: rubysmithing-tui
description: Terminal UI scaffolding sub-skill for Ruby projects using the Charm/Bubble ecosystem (bubbletea-ruby, lipgloss-ruby, bubbles-ruby, huh-ruby, gum-ruby, ntcharts-ruby, bubblezone-ruby). Use when building any interactive terminal interface — file browsers, dashboards, configuration panels, RAG viewers, agent control panels, human-in-the-loop components, or any multi-panel TUI. Always produces a full skeleton: app.rb entry point + screens/ directory + components/ stubs. Detects intent (scaffold vs advisor) and queries rubysmithing-context for current Bubble gem API syntax before generating.
---

# Rubysmithing — TUI

Scaffolder and advisor for terminal UI applications using the Ruby Charm/Bubble ecosystem.
Always produces a full skeleton even for simple requests — screens and components
start minimal but with the correct structural hooks.

## Ecosystem Reference

```
Architecture:   bubbletea-ruby (Elm: Model / Update / View)
Styling:        lipgloss-ruby  (CSS-like terminal layout)
Components:     bubbles-ruby   (reusable UI widgets)
Mouse Input:    bubblezone-ruby
Forms:          huh-ruby
Shell Prompts:  gum-ruby
Charts:         ntcharts-ruby
Markdown:       glamour-ruby
Animation:      harmonica-ruby
```

Load `references/tui-patterns.md` for component patterns and layout recipes.

## Pre-Scaffold Steps

1. **Trigger rubysmithing-context** for bubbletea, lipgloss, and any other Bubble gems
   involved in the specific request
2. **Extract application domain** from the request — what does this TUI control?
3. **Identify screens** — what distinct views does the user need?
4. **Identify components** per screen — lists, forms, text areas, charts, panels
5. **Identify data flows** — what external systems does this TUI interact with?

## Skeleton Structure

Always produce this full structure, even if most files start nearly empty:

```
[app_name]/
├── app.rb                        # Entry point, BubbleTea::Program boot
├── lib/
│   └── [app_name]/
│       ├── app.rb                # Root App model (Model / Update / View)
│       ├── screens/
│       │   ├── [screen_name].rb  # One file per screen
│       │   └── ...
│       └── components/
│           ├── [component].rb    # Reusable components
│           └── ...
└── Gemfile
```

Zeitwerk autoloads everything under `lib/`. The root `app.rb` sets up Zeitwerk
and boots the BubbleTea program.

## BubbleTea Architecture Conventions

Every screen and the root app follows the Elm pattern:

```ruby
# frozen_string_literal: true

module MyApp
  class App
    # Model — pure data, no logic
    State = Struct.new(
      :active_screen,
      :loading,
      # ... domain state
      keyword_init: true
    )

    def initialize
      @state = State.new(active_screen: :main, loading: false)
    end

    # Update — pure function: (state, message) -> new_state
    def update(message)
      case message
      when :quit then BubbleTea::Quit
      # ... message handlers
      end
    end

    # View — pure function: state -> string
    def view
      # Lipgloss layout composition
    end
  end
end
```

**State is always a Struct with keyword_init: true.**
**Update returns new state — never mutate @state directly.**
**View is a pure function — no side effects.**

## Screen Patterns by Domain

### File Browser (e.g. GDrive interface)
Components needed:
- `FileListComponent` — scrollable list with cursor (bubbles List)
- `PreviewPaneComponent` — content viewer (glamour for markdown files)
- `StatusBarComponent` — current path, selection count
- `ActionMenuComponent` — context actions (open, edit, export, backup)

Screens:
- `BrowserScreen` — main file tree view
- `EditorScreen` — file editor (bubbles TextArea or external editor bridge)
- `ExportScreen` — huh form for format selection and destination

### RAG / AI Configuration
Components needed:
- `ParamFormComponent` — huh form for model/temperature/k params
- `ChunkingOptionsComponent` — huh form for segmentation strategy
- `DatabaseOptionsComponent` — connection and index config
- `VectorViewerComponent` — ntcharts visualization of embedding clusters
- `ResultsViewerComponent` — retrieved chunks with scores (glamour rendered)
- `HumanInLoopComponent` — approve/reject/edit retrieved context before generation

Screens:
- `ConfigScreen` — all parameter forms
- `IngestScreen` — document ingestion progress (streaming progress bar)
- `QueryScreen` — interactive RAG query with results viewer
- `HilScreen` — human-in-the-loop review interface

### Agent Control Panel
Components needed:
- `AgentStatusComponent` — current state, active tool, token count
- `ToolCallLogComponent` — scrollable log of tool invocations
- `StreamingOutputComponent` — live LLM response stream
- `InterventionComponent` — pause/resume/redirect agent

### Dashboard / Monitoring
Components needed:
- `MetricsChartComponent` — ntcharts line/bar charts
- `LogViewerComponent` — scrollable structured log (journald integration)
- `StatusGridComponent` — service health grid

## Lipgloss Layout Conventions

```ruby
# Standard two-pane layout
sidebar = Lipgloss::Style.new
  .width(30)
  .border(:rounded)
  .padding(0, 1)

main_pane = Lipgloss::Style.new
  .border(:rounded)
  .padding(0, 1)

layout = Lipgloss.join_horizontal(
  Lipgloss::Align::TOP,
  sidebar.render(sidebar_content),
  main_pane.render(main_content)
)
```

Always define styles as constants in a `Styles` module, not inline in `view`.

## Output Format

For every scaffold:
1. **Full file tree** — show every file to be created
2. **Complete content for each file** — no stubs left empty except clearly marked TODO screens
3. **Gemfile additions** — all Bubble gems required
4. **Boot instructions** — how to run (`ruby app.rb` or `bundle exec ruby app.rb`)
5. **Extension points** — one comment per screen noting where domain logic connects

For advisory responses:
1. **Direct recommendation** with component/gem choice rationale
2. **Minimal code snippet** showing the specific pattern
3. **No full scaffold** unless the user asks for it

## Spec Generation

Generate RSpec specs only when explicitly requested. When requested:
- Focus on Update function (pure, testable without rendering)
- Test state transitions, not view output
- File: `spec/[path]_spec.rb`
