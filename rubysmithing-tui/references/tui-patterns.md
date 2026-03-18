# TUI Patterns

Component patterns and layout recipes for the Ruby Charm/Bubble ecosystem.
Always verify current gem API syntax via rubysmithing-context before generating.
Context7 IDs: bubbletea `/marcoroth/bubbletea-ruby`, lipgloss `/marcoroth/lipgloss-ruby`,
bubbles `/marcoroth/bubbles-ruby`, huh `/marcoroth/huh-ruby`, gum `/marcoroth/gum-ruby`,
ntcharts `/marcoroth/ntcharts-ruby`

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

## Bubbles::TextInput Component

Interactive single-line text input with validation, suggestions, and styling:

```ruby
# lib/[app_name]/components/text_input_form.rb
# Query: /marcoroth/bubbles-ruby "TextInput placeholder validation suggestions"

module MyApp
  module Components
    class TextInputForm
      def initialize
        @input = Bubbles::TextInput.new
        @input.placeholder = "Enter your username..."
        @input.prompt = "> "
        @input.char_limit = 20
        @input.width = 30
        @input.focus

        # Optional: Password mode
        # @input.echo_mode = :password
        # @input.echo_character = "*"

        # Optional: Suggestions/autocomplete
        @input.suggestions = ["admin", "administrator", "user", "guest"]
        @input.show_suggestions = true

        # Optional: Validation
        @input.validate = ->(value) {
          return StandardError.new("Too short") if value.length < 3
          nil
        }
      end

      def update(message)
        @input, command = @input.update(message)
        [self, command]
      end

      def view
        error_text = @input.error&.message ? "\n#{@input.error.message}" : ""
        "#{@input.view}#{error_text}"
      end

      def value = @input.value
      def reset = @input.reset
      def focused? = @input.focused?
    end
  end
end

# Key bindings for TextInput:
# Left/Right, Ctrl+B/F - Move cursor
# Home/End, Ctrl+A/E   - Jump to start/end
# Backspace, Delete    - Delete characters
# Ctrl+K/U             - Delete to end/start of line
# Ctrl+W, Alt+Backspace - Delete word backward
# Tab                  - Accept suggestion
# Up/Down              - Cycle through suggestions
```

---

## Bubbles::List Component

Selectable list with navigation, filtering, and item management:

```ruby
# lib/[app_name]/components/item_list.rb
# Query: /marcoroth/bubbles-ruby "List items selection navigation"

module MyApp
  module Components
    class ItemList
      def initialize(items)
        @list = Bubbles::List.new(items, width: 50, height: 12)
        @list.title = "Items"
        @adding = false
        @input = Bubbles::TextInput.new
        @input.placeholder = "New item..."
        @input.prompt = "> "
      end

      def update(message)
        if @adding
          return handle_adding_mode(message)
        end

        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "a"  # Add item
            @adding = true
            @input.reset
            return [self, @input.focus]
          when "d"  # Delete item
            idx = @list.selected_index
            items = @list.items.dup
            items.delete_at(idx) if idx < items.length
            @list.items = items
          when "enter"  # Toggle item state (if items are hashes)
            toggle_item_state
          end
        end

        @list, command = @list.update(message)
        [self, command]
      end

      def view
        if @adding
          "Add new item:\n#{@input.view}\n\nPress Enter to add, Esc to cancel"
        else
          @list.view
        end
      end

      private

      def handle_adding_mode(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "enter"
            unless @input.value.empty?
              items = @list.items.dup
              items << @input.value  # or build item hash
              @list.items = items
            end
            @adding = false
            @input.blur
            return [self, nil]
          when "esc"
            @adding = false
            @input.blur
            return [self, nil]
          end
        end

        @input, command = @input.update(message)
        [self, command]
      end

      def toggle_item_state
        idx = @list.selected_index
        items = @list.items.dup
        if items[idx].is_a?(Hash) && items[idx].key?(:done)
          items[idx][:done] = !items[idx][:done]
          @list.items = items
        end
      end
    end
  end
end
```

---

## Bubbles::Spinner Component

Animated loading indicators with multiple styles:

```ruby
# lib/[app_name]/components/loading_spinner.rb
# Query: /marcoroth/bubbles-ruby "Spinner animation styles"

module MyApp
  module Components
    class LoadingSpinner
      def initialize(message: "Loading...", style: Bubbles::Spinners::DOT)
        @spinner = Bubbles::Spinner.new(spinner: style)
        @message = message
        # Optional: Apply styling with Lipgloss
        # @spinner.style = Lipgloss::Style.new.foreground("205")
      end

      def init
        [self, @spinner.tick]  # Start animation
      end

      def update(message)
        case message
        when Bubbles::Spinner::TickMessage
          @spinner, command = @spinner.update(message)
          return [self, command]
        end
        [self, nil]
      end

      def view
        "#{@spinner.view} #{@message}"
      end

      def stop
        @spinner.stop
      end
    end
  end
end

# Available spinner styles:
# Bubbles::Spinners::LINE      # |, /, -, \
# Bubbles::Spinners::DOT       # Braille dots (default)
# Bubbles::Spinners::MINI_DOT  # Small braille dots
# Bubbles::Spinners::JUMP      # Jumping dot
# Bubbles::Spinners::PULSE     # Block pulse
# Bubbles::Spinners::POINTS    # Three dots
# Bubbles::Spinners::GLOBE     # Earth emoji rotation
# Bubbles::Spinners::MOON      # Moon phases
# Bubbles::Spinners::MONKEY    # See/hear/speak no evil
# Bubbles::Spinners::METER     # Loading meter
# Bubbles::Spinners::HAMBURGER # Hamburger menu animation
# Bubbles::Spinners::ELLIPSIS  # Growing ellipsis
```

---

## Bubbles::Cursor Component

Customizable blinking cursor for text interfaces:

```ruby
# lib/[app_name]/components/custom_cursor.rb
# Query: /marcoroth/bubbles-ruby "Cursor blink mode character"

module MyApp
  module Components
    class CustomCursor
      def initialize(char: "_", blink_speed: 0.53)
        @cursor = Bubbles::Cursor.new
        @cursor.char = char
        @cursor.blink_speed = blink_speed
        @mode_index = 0
        @modes = [:blink, :static, :hide]
      end

      def init
        [self, @cursor.focus]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "m"
            @mode_index = (@mode_index + 1) % @modes.length
            return [self, @cursor.set_mode(@modes[@mode_index])]
          end
        when Bubbles::Cursor::BlinkMessage, Bubbles::Cursor::InitialBlinkMessage
          @cursor, command = @cursor.update(message)
          return [self, command]
        end
        [self, nil]
      end

      def view
        @cursor.view
      end

      def set_mode(mode)
        @cursor.set_mode(mode)
      end
    end
  end
end

# Cursor modes:
# Bubbles::Cursor::MODE_BLINK  - Blinking cursor (default)
# Bubbles::Cursor::MODE_STATIC - Always visible cursor
# Bubbles::Cursor::MODE_HIDE   - Hidden cursor

# Methods:
# cursor.focus        - Enable cursor and start blinking
# cursor.blur         - Disable cursor
# cursor.set_mode(m)  - Change display mode
# cursor.char = "x"   - Set character under cursor
# cursor.blink?       - Current blink state
# cursor.focused?     - Whether cursor is focused
```

---

## Bubbles::Help Component

Dynamic help display for key bindings:

```ruby
# lib/[app_name]/components/help_display.rb
# Query: /marcoroth/bubbles-ruby "Help key bindings toggle"

module MyApp
  module Components
    class HelpDisplay
      # Define key bindings with help text
      KEYS = {
        up: Bubbles::Key.binding(keys: ["up", "k"], help: ["↑/k", "up"]),
        down: Bubbles::Key.binding(keys: ["down", "j"], help: ["↓/j", "down"]),
        select: Bubbles::Key.binding(keys: ["enter"], help: ["enter", "select"]),
        filter: Bubbles::Key.binding(keys: ["/"], help: ["/", "filter"]),
        help: Bubbles::Key.binding(keys: ["?"], help: ["?", "toggle help"]),
        quit: Bubbles::Key.binding(keys: ["q", "ctrl+c"], help: ["q", "quit"]),
      }

      def initialize
        @help = Bubbles::Help.new
        @help.width = 80
        @help.short_separator = " • "
        @show_full_help = false
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          if Bubbles::Key.matches?(message, KEYS[:help])
            @show_full_help = !@show_full_help
          end
        end
        [self, nil]
      end

      def view
        if @show_full_help
          @help.full_help_view([
            [KEYS[:up], KEYS[:down], KEYS[:select]],
            [KEYS[:filter], KEYS[:help], KEYS[:quit]]
          ])
        else
          @help.short_help_view([KEYS[:help], KEYS[:quit]])
        end
      end

      def toggle_help
        @show_full_help = !@show_full_help
      end
    end
  end
end

# Short help view renders inline: "? toggle help • q quit"
# Full help view renders in columns:
#   ↑/k up      / filter
#   ↓/j down    ? toggle help
#   enter select q quit

# Key.binding options:
# keys: ["key1", "key2"]  - Keys that trigger this binding
# help: ["display", "description"] - Help text [key_label, action_description]
# enabled: true/false     - Whether binding is active

# Key.matches?(message, binding) - Check if key message matches binding
```

---

## Gum Utility Functions

External prompt utilities for setup, configuration, and modal interactions:

```ruby
# lib/[app_name]/components/gum_prompts.rb
# Query: /marcoroth/gum-ruby "input choose filter style"

module MyApp
  module Components
    class GumPrompts
      # Single-line text input
      def self.prompt_input(placeholder: nil, password: false, **options)
        Gum.input(
          placeholder: placeholder,
          password: password,
          **options
        )
      end

      # Selection menu (single choice)
      def self.prompt_choice(items, header: nil, **options)
        Gum.choose(
          items,
          header: header,
          **options
        )
      end

      # Multiple selection
      def self.prompt_multi_choice(items, limit: nil, **options)
        opts = limit ? { limit: limit } : { no_limit: true }
        Gum.choose(
          items,
          **opts,
          **options
        )
      end

      # Filtered search and selection
      def self.prompt_filter(items, placeholder: "Search...", **options)
        Gum.filter(
          items,
          placeholder: placeholder,
          **options
        )
      end

      # Styled text output
      def self.styled_text(text, **styles)
        Gum.style(text, **styles)
      end

      # Configuration form example
      def self.configuration_wizard
        model = prompt_choice(
          ["claude-sonnet-4-5", "claude-opus-4-5", "gpt-4o"],
          header: "Select LLM Model:"
        )

        temperature = prompt_input(
          placeholder: "0.7",
          header: "Temperature (0.0-2.0):"
        )

        k_results = prompt_input(
          placeholder: "5",
          header: "Top-K results:"
        )

        {
          model: model,
          temperature: temperature.to_f,
          k: k_results.to_i
        }
      end
    end
  end
end

# Styling options for Gum.style:
# foreground: "212" (color number or hex)
# background: "240"
# bold: true/false
# border: :double, :rounded, :thick, :normal, :none
# border_foreground: "212"
# align: :center, :left, :right
# width: 50
# height: 10
# margin: "1 2" (top/bottom left/right)
# padding: "2 4"
```

---

## Complete Todo Application Example

Integration of multiple Bubbles components in a working application:

```ruby
# lib/[app_name]/apps/todo_app.rb
# Query: /marcoroth/bubbles-ruby "todo application list input help"

module MyApp
  module Apps
    class TodoApp
      include Bubbletea::Model

      KEYS = {
        up: Bubbles::Key.binding(keys: ["up", "k"], help: ["↑/k", "up"]),
        down: Bubbles::Key.binding(keys: ["down", "j"], help: ["↓/j", "down"]),
        add: Bubbles::Key.binding(keys: ["a"], help: ["a", "add"]),
        delete: Bubbles::Key.binding(keys: ["d"], help: ["d", "delete"]),
        quit: Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"]),
      }

      def initialize
        @todos = [
          { title: "Learn Bubble Tea", done: false },
          { title: "Build a TUI app", done: false },
          { title: "Ship to production", done: false },
        ]

        @list = Bubbles::List.new(@todos, width: 50, height: 12)
        @list.title = "My Todos"

        @input = Bubbles::TextInput.new
        @input.placeholder = "New todo..."
        @input.prompt = "> "

        @help = Bubbles::Help.new
        @adding = false
      end

      def init
        [self, nil]
      end

      def update(message)
        if @adding
          return handle_adding(message)
        end

        case message
        when Bubbletea::KeyMessage
          if Bubbles::Key.matches?(message, KEYS[:quit])
            return [self, Bubbletea.quit]
          elsif Bubbles::Key.matches?(message, KEYS[:add])
            @adding = true
            @input.reset
            return [self, @input.focus]
          elsif Bubbles::Key.matches?(message, KEYS[:delete])
            idx = @list.selected_index
            @todos.delete_at(idx) if idx < @todos.length
            @list.items = @todos
          elsif message.to_s == "enter"
            idx = @list.selected_index
            @todos[idx][:done] = !@todos[idx][:done] if idx < @todos.length
            @list.items = @todos
          end
        end

        @list, command = @list.update(message)
        [self, command]
      end

      def view
        if @adding
          "Add new todo:\n#{@input.view}\n\nPress Enter to add, Esc to cancel"
        else
          help = @help.short_help_view([KEYS[:add], KEYS[:delete], KEYS[:quit]])
          "#{@list.view}\n\n#{help}"
        end
      end

      private

      def handle_adding(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "enter"
            unless @input.value.empty?
              @todos << { title: @input.value, done: false }
              @list.items = @todos
            end
            @adding = false
            @input.blur
            return [self, nil]
          when "esc"
            @adding = false
            @input.blur
            return [self, nil]
          end
        end

        @input, command = @input.update(message)
        [self, command]
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
