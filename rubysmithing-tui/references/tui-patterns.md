# TUI Patterns

Component patterns and layout recipes for the Ruby Charm/Bubble ecosystem.
Always verify current gem API syntax via rubysmithing-context before generating.
Context7 IDs: bubbletea `/marcoroth/bubbletea-ruby`, lipgloss `/marcoroth/lipgloss-ruby`,
huh `/marcoroth/huh-ruby`, gum `/marcoroth/gum-ruby`, ntcharts `/marcoroth/ntcharts-ruby`

---

## BubbleTea Application Lifecycle

Every app follows the Elm Model / Update / View pattern:

```
Init → Model
       ↓
User input / message → Update → new Model
                                  ↓
                               View → rendered string
```

**Key invariants:**
- Model is always a Struct with `keyword_init: true`
- Update returns new state — never mutate instance variables directly
- View is a pure function — no I/O, no side effects
- Messages are symbols or small value objects

---

## Root App Structure

```ruby
# frozen_string_literal: true
# lib/[app_name]/app.rb
# Query: /marcoroth/bubbletea-ruby "program model update view"

module MyApp
  class App
    # ── Model ──────────────────────────────────────────────────────────────
    State = Struct.new(
      :active_screen,   # Symbol — current screen key
      :screens,         # Hash{Symbol => Screen instance}
      :status_message,  # String | nil
      :loading,         # Boolean
      keyword_init: true
    )

    def initialize
      @state = State.new(
        active_screen: :main,
        screens: {
          main: Screens::Main.new,
          # add screens here
        },
        status_message: nil,
        loading: false
      )
    end

    # ── Update ─────────────────────────────────────────────────────────────
    def update(message)
      case message
      in :quit
        BubbleTea::Quit
      in { switch_screen: Symbol => screen }
        @state = @state.with(active_screen: screen)
      in { status: String => msg }
        @state = @state.with(status_message: msg)
      else
        # Delegate to active screen
        active_screen.update(message)
      end
    end

    # ── View ───────────────────────────────────────────────────────────────
    def view
      Lipgloss.join_vertical(
        Lipgloss::Align::LEFT,
        header_view,
        active_screen.view,
        status_bar_view
      )
    end

    private

    def active_screen = @state.screens[@state.active_screen]

    def header_view
      Styles::HEADER.render(" #{APP_NAME} ")
    end

    def status_bar_view
      msg = @state.status_message || " Ready"
      Styles::STATUS_BAR.render(msg)
    end
  end
end
```

---

## Styles Module

Define all styles as constants, never inline in `view`:

```ruby
# frozen_string_literal: true
# lib/[app_name]/styles.rb
# Query: /marcoroth/lipgloss-ruby "style border padding color"

module MyApp
  module Styles
    HEADER = Lipgloss::Style.new
      .bold(true)
      .foreground(Lipgloss::Color.new("#FFFFFF"))
      .background(Lipgloss::Color.new("#5C5C5C"))
      .padding(0, 1)
      .width(80)

    STATUS_BAR = Lipgloss::Style.new
      .foreground(Lipgloss::Color.new("#AAAAAA"))
      .padding(0, 1)

    PANEL = Lipgloss::Style.new
      .border(:rounded)
      .border_foreground(Lipgloss::Color.new("#444444"))
      .padding(0, 1)

    ACTIVE_PANEL = PANEL.copy
      .border_foreground(Lipgloss::Color.new("#7DCFFF"))

    SIDEBAR = Lipgloss::Style.new
      .width(30)
      .border(:rounded)
      .padding(0, 1)

    MAIN_PANE = Lipgloss::Style.new
      .border(:rounded)
      .padding(0, 1)
  end
end
```

---

## Screen Pattern

Each screen is an independent Model / Update / View unit:

```ruby
# frozen_string_literal: true
# lib/[app_name]/screens/[name]_screen.rb

module MyApp
  module Screens
    class MainScreen
      State = Struct.new(
        :items,
        :cursor,
        :selected,
        keyword_init: true
      )

      def initialize
        @state = State.new(items: [], cursor: 0, selected: nil)
      end

      def update(message)
        case message
        in :cursor_up
          @state = @state.with(cursor: [@state.cursor - 1, 0].max)
        in :cursor_down
          @state = @state.with(cursor: [@state.cursor + 1, @state.items.length - 1].min)
        in :select
          @state = @state.with(selected: @state.items[@state.cursor])
        end
      end

      def view
        items_view = @state.items.each_with_index.map do |item, i|
          prefix = i == @state.cursor ? "▶ " : "  "
          "#{prefix}#{item}"
        end.join("\n")

        Styles::PANEL.render(items_view)
      end
    end
  end
end
```

---

## Two-Pane Layout

```ruby
# Sidebar + main content — common pattern for file browsers, RAG viewers, etc.
def view
  sidebar = Styles::SIDEBAR.render(sidebar_content)
  main    = Styles::MAIN_PANE.render(main_content)

  Lipgloss.join_horizontal(Lipgloss::Align::TOP, sidebar, main)
end
```

---

## Huh Form Component

```ruby
# frozen_string_literal: true
# lib/[app_name]/components/config_form.rb
# Query: /marcoroth/huh-ruby "form group select input"

module MyApp
  module Components
    class ConfigForm
      Result = Struct.new(:model, :temperature, :k, keyword_init: true)

      def run
        # Verify current Huh form API via Context7 before use
        form = Huh::Form.new(
          Huh::Group.new(
            Huh::Select.new(key: :model, title: "LLM Model")
              .options(["claude-sonnet-4-5", "claude-opus-4-5", "gpt-4o"]),
            Huh::Input.new(key: :temperature, title: "Temperature")
              .placeholder("0.7")
              .validate(->(v) { v.to_f.between?(0, 2) }, "Must be 0.0–2.0"),
            Huh::Input.new(key: :k, title: "Top-K results")
              .placeholder("5")
          )
        )

        values = form.run
        Result.new(**values)
      end
    end
  end
end
```

---

## NTCharts Metrics Panel

```ruby
# lib/[app_name]/components/metrics_chart.rb
# Query: /marcoroth/ntcharts-ruby "line chart data series"

module MyApp
  module Components
    class MetricsChart
      def initialize(title:)
        @title = title
        @data  = []
      end

      def push(value)
        @data << value
        @data = @data.last(60)  # rolling window
      end

      def view
        # Verify NTCharts API via Context7 before use
        chart = NTCharts::LineChart.new(
          title: @title,
          data: @data,
          width: 50,
          height: 10
        )
        Styles::PANEL.render(chart.render)
      end
    end
  end
end
```

---

## Mouse Zones (bubblezone)

```ruby
# Query: /marcoroth/bubblezone-ruby "zone register click"
# Add to view output, detect in update

module MyApp
  class App
    def view
      content = BubbleZone::Manager.new do |m|
        m.mark("file-list",  file_list_view)
        m.mark("action-bar", action_bar_view)
      end
      Styles::PANEL.render(content)
    end

    def update(message)
      case message
      in BubbleZone::MouseMessage => mouse
        case mouse.zone
        in "file-list"  then handle_file_click(mouse)
        in "action-bar" then handle_action_click(mouse)
        end
      end
    end
  end
end
```

---

## Streaming Output Component

For live LLM response rendering inside a TUI panel:

```ruby
# lib/[app_name]/components/streaming_output.rb

module MyApp
  module Components
    class StreamingOutput
      def initialize
        @buffer = +""   # unfrozen string for mutation
        @complete = false
      end

      def append(chunk)
        @buffer << chunk
      end

      def complete! = @complete = true
      def complete? = @complete

      def view
        rendered = Glamour.render(@buffer)  # markdown → terminal
        label = @complete ? "" : " ▌"       # blinking cursor while streaming
        Styles::MAIN_PANE.render(rendered + label)
      end
    end
  end
end
```

---

## Human-in-the-Loop Component

```ruby
# lib/[app_name]/components/hil_review.rb
# Used in RAG pipelines, agent oversight, document review

module MyApp
  module Components
    class HilReview
      Decision = Struct.new(:action, :edited_content, keyword_init: true)
      ACTIONS = %i[approve reject edit skip].freeze

      def initialize(content:, source: nil)
        @content = content
        @source  = source
      end

      def run
        puts Glamour.render("### Review Required\n\n#{@content}")
        puts "Source: #{@source}" if @source

        action = Gum.choose(*ACTIONS.map(&:to_s), header: "Action:")
        action = action.strip.to_sym

        if action == :edit
          edited = Gum.write(value: @content, header: "Edit content:")
          Decision.new(action: :approve, edited_content: edited)
        else
          Decision.new(action: action, edited_content: nil)
        end
      end
    end
  end
end
```

---

## Entry Point (app.rb)

```ruby
# frozen_string_literal: true
# app.rb — project root entry point

require "zeitwerk"
require "bundler/setup"

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/lib")
loader.setup

# Query: /marcoroth/bubbletea-ruby "program run"
program = BubbleTea::Program.new(MyApp::App.new)
program.run
```
