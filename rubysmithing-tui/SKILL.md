---
name: rubysmithing-tui
description: Terminal UI scaffolder and advisor for Ruby projects using the Charm/Bubble ecosystem. Activates on any mention of: TUI, terminal UI, terminal interface, terminal app, BubbleTea, bubbletea, Lipgloss, lipgloss, Bubbles, bubbles (UI components), Huh, huh form, form validation, Gum, gum prompts, NTCharts, charts, data visualization, Bubblezone, Glamour, glamour rendering, markdown display, Harmonica, harmonica animations, spring physics, smooth transitions, animated scrolling, file browser, file picker, directory browser, interactive terminal, multi-panel, split pane, sidebar, dashboard, control panel, monitor, keyboard navigation, cursor movement, human in the loop component, HIL interface, RAG viewer, agent control panel, streaming output panel, text input, spinner, list selection, metrics display, animated transitions, or progress bar within a terminal context. Always runs rubysmithing-context as prerequisite for Bubble gem API verification. Always produces full skeleton: app.rb + screens/ + components/ stubs. Specs only on explicit request.
---

# Rubysmithing — TUI

Scaffolder and advisor for terminal UI applications using the Ruby Charm/Bubble ecosystem.
Always produces a full skeleton. Generates against verified API syntax only.

## Step 1: Prerequisites (Always Run First)

Before generating any scaffold or component code:

1. **Activate rubysmithing-context** for each Bubble gem involved:
   bubbletea, lipgloss, bubbles (UI components), huh (forms), glamour (markdown), ntcharts (visualization), harmonica (animations), and any of: gum, bubblezone.
   Generate no component code until API syntax is confirmed or WARNING block is injected.

2. **Extract domain** from the request — what does this TUI control or display?

3. **Identify screens** — what distinct views does the user need?

4. **Identify components per screen** — lists, forms, text areas, charts, panels.

5. **Identify external data flows** — what systems does this TUI interact with?
   If AI/LLM systems are involved, note the rubysmithing-genai dependency.

**Compound prompts** (e.g., "refactor this RAG pipeline AND build a TUI for it"):
Handle the TUI component here. State explicitly:
"Handling the TUI dashboard component. The RAG pipeline component should be
addressed with rubysmithing-genai."

## Step 2: Detect Mode

**Scaffolding** — triggered by: create, build, scaffold, generate, write a TUI for.
Output: full skeleton (see structure below) + complete file content.

**Advisory** — triggered by: how do I, which component, explain, what's the best way.
Output: recommendation + minimal snippet. No full scaffold unless asked.

## Skeleton Structure (always output this shape)

```
[app_name]/
├── app.rb                               # Zeitwerk boot + BubbleTea::Program
├── Gemfile
└── lib/
    └── [app_name]/
        ├── app.rb                       # Root App model (Model / Update / View)
        ├── styles.rb                    # All Lipgloss styles as constants
        ├── screens/
        │   └── main.rb                  # Starter main screen
        └── components/
            └── .keep                    # Stub; domain components added here
```

Copy the base skeleton from `assets/skeleton/` and rename `app_name` → the
actual application name (snake_case for files, CamelCase for module).

## Internal Component DSL

To protect against Bubble ecosystem API churn, generate TUI component code
through a stable internal adapter pattern rather than calling Bubble gem APIs directly
in every file. Define a thin `Components::Base` adapter in each scaffold:

```ruby
# lib/[app_name]/components/base.rb
# frozen_string_literal: true

module AppName
  module Components
    # Internal adapter — isolates Bubble gem API surface.
    # If bubbletea/lipgloss/bubbles APIs change, update here only.
    module Base
      # Layout helpers
      def self.panel(content, style: Styles::PANEL)
        style.render(content)
      end

      def self.join_vertical(*parts)
        Lipgloss.join_vertical(Lipgloss::Align::LEFT, *parts)
      end

      def self.join_horizontal(*parts)
        Lipgloss.join_horizontal(Lipgloss::Align::TOP, *parts)
      end

      # Bubbles component wrappers
      def self.text_input(**options)
        input = Bubbles::TextInput.new
        options.each { |key, value| input.public_send("#{key}=", value) }
        input
      end

      def self.list(items, **options)
        list = Bubbles::List.new(items)
        options.each { |key, value| list.public_send("#{key}=", value) }
        list
      end

      def self.spinner(style: Bubbles::Spinners::DOT)
        Bubbles::Spinner.new(spinner: style)
      end

      # Gum utilities (for forms outside main TUI loop)
      def self.prompt_input(**options)
        Gum.input(**options)
      end

      def self.prompt_choose(items, **options)
        Gum.choose(items, **options)
      end

      def self.prompt_filter(items, **options)
        Gum.filter(items, **options)
      end

      # Huh form components (for complex forms)
      def self.form_input(key:, title:, **options)
        Huh.input.key(key).title(title).tap do |input|
          options.each { |k, v| input.public_send(k, v) }
        end
      end

      def self.form_select(key:, title:, options:, **config)
        Huh.select.key(key).title(title).options(*options).tap do |select|
          config.each { |k, v| select.public_send(k, v) }
        end
      end

      def self.form_confirm(key:, title:, **options)
        Huh.confirm.key(key).title(title).tap do |confirm|
          options.each { |k, v| confirm.public_send(k, v) }
        end
      end

      # Glamour markdown rendering
      def self.render_markdown(content, **options)
        Glamour.render(content, **options)
      end

      def self.markdown_renderer(**options)
        Glamour::Renderer.new(**options)
      end

      # NTCharts data visualization
      def self.line_chart(width, height, min_x, max_x, min_y, max_y)
        Ntcharts::Linechart.new(width, height, min_x, max_x, min_y, max_y)
      end

      def self.time_series_chart(width, height)
        Ntcharts::Timeserieslinechart.new(width, height)
      end

      def self.bar_chart(width, height)
        Ntcharts::Barchart.new(width, height)
      end

      # Harmonica spring animations
      def self.spring_animation(fps: 60, frequency: 6.0, damping: 0.5)
        Harmonica::Spring.new(
          delta_time: Harmonica.fps(fps),
          angular_frequency: frequency,
          damping_ratio: damping
        )
      end

      def self.smooth_spring(fps: 60)
        spring_animation(fps: fps, frequency: 5.0, damping: 1.0)  # Critically damped
      end

      def self.bouncy_spring(fps: 60)
        spring_animation(fps: fps, frequency: 6.0, damping: 0.3)  # Bouncy
      end
    end
  end
end
```

All screens and components call `Components::Base.panel(...)` and
`Components::Base.join_vertical(...)` rather than `Styles::X.render(...)` or
`Lipgloss.join_*` directly. If the Lipgloss API changes, only `components/base.rb`
needs updating.

## BubbleTea Conventions

- State is always `Struct.new(keyword_init: true)` — never instance variables mutated directly
- Update is a pure function: receives message, returns new state or `BubbleTea::Quit`
- View is a pure function: no I/O, no side effects
- Styles are module-level constants in `styles.rb` — never inline in `view`

## Patterns Reference

Load `references/tui-patterns.md` for:
- Root App and Screen structural templates
- Styles module conventions
- Two-pane layout recipe
- Bubbles::TextInput for interactive text entry
- Bubbles::List for item selection and navigation
- Bubbles::Spinner for loading states
- Bubbles::Cursor for custom text cursors
- Bubbles::Help for key binding documentation
- Gum utility functions for external prompts
- Huh form components with validation and themes
- Huh input, select, and confirm fields
- Glamour markdown rendering with custom styles
- Glamour renderer instances for consistent formatting
- NTCharts line charts and time series visualization
- NTCharts bar charts and data display
- Harmonica spring animations for smooth transitions
- Harmonica animated scrolling and UI state changes
- Mouse zones (bubblezone)
- Streaming output component
- Human-in-the-loop component
- Entry point (app.rb) template

## Domain → Component Mapping

| Domain | Screens | Key Components |
| :---- | :---- | :---- |
| File browser (GDrive etc.) | Browser, Editor, Export | AnimatedFileList (Bubbles::List + Harmonica), PreviewPane (Glamour), StatusBar, ActionMenu |
| RAG configurator | Config, Ingest, Query, HIL | ConfigForm (Huh::Form), ChunkingOptions, ResultsViewer (Glamour), HilReview |
| Agent control panel | Dashboard, ToolLog | AgentStatus, ToolCallLog, StreamingOutput (Glamour), Intervention (Gum prompts) |
| Monitoring / metrics | Dashboard | MetricsChart (NTCharts), LogViewer (Glamour), StatusGrid, LoadingSpinner (Bubbles::Spinner) |
| Data entry forms | Input, Validation, Review | ConfigForm (Huh::Form), FormFields, ValidationPanel |
| Search/Filter interfaces | Search, Results, Filter | SearchInput (Bubbles::TextInput), FilteredList (Bubbles::List + Harmonica), ResultsPane |
| Documentation viewer | Reader, Search, TOC | ContentViewer (Glamour), AnimatedNavigation (Bubbles::List + Harmonica), SearchBar |
| Analytics dashboard | Overview, Charts, Reports | TimeSeriesChart (NTCharts), MetricsPanels, DataTable (Bubbles::List) |
| Interactive tutorials | Steps, Progress, Navigation | ProgressBar (Harmonica), StepNavigation, ContentDisplay (Glamour) |
| Live data feeds | Stream, Filters, Controls | SmoothScrolling (Harmonica), DataList (Bubbles::List), FilterControls |

## Output Format

For scaffolds:
1. **Full file tree** — every file to be created
2. **Complete content** for each file — screens/components left as minimal stubs only if
   they require domain-specific data flows not yet defined
3. **Gemfile additions** — all Bubble gems required
4. **Boot instruction** — `bundle exec ruby app.rb`
5. **Context7 IDs used** — or WARNING blocks if resolution failed

For advisory:
1. **Direct recommendation** with gem/component rationale
2. **Minimal snippet** for the specific pattern
3. **No full scaffold** unless asked

## Specs

Generate RSpec specs only when explicitly requested:
- Test Update function (pure, testable without rendering)
- Focus on state transitions, not view output
- File: `spec/[path]_spec.rb`
