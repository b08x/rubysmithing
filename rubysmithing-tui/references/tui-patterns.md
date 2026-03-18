# TUI Patterns

Component patterns and layout recipes for the Ruby Charm/Bubble ecosystem.
Always verify current gem API syntax via rubysmithing-context before generating.
Context7 IDs: bubbletea `/marcoroth/bubbletea-ruby`, lipgloss `/marcoroth/lipgloss-ruby`,
bubbles `/marcoroth/bubbles-ruby`, huh `/marcoroth/huh-ruby`, gum `/marcoroth/gum-ruby`,
ntcharts `/marcoroth/ntcharts-ruby`, glamour `/marcoroth/glamour-ruby`, harmonica `/marcoroth/harmonica-ruby`

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

## Huh Form Components

Interactive form building with validation, themes, and structured input handling:

```ruby
# lib/[app_name]/components/configuration_form.rb
# Query: /marcoroth/huh-ruby "form input select confirm validation"

module MyApp
  module Components
    class ConfigurationForm
      def initialize
        @form = Huh.form(
          Huh.group(
            # Text input with validation
            Huh.input
              .key("name")
              .title("What's your name?")
              .placeholder("Enter your name...")
              .validate(Huh::Validation.not_empty),

            # Email with format validation
            Huh.input
              .key("email")
              .title("Email address")
              .placeholder("you@example.com")
              .validate(Huh::Validation.all(
                Huh::Validation.not_empty,
                Huh::Validation.email
              )),

            # Password input
            Huh.input
              .key("password")
              .title("Password")
              .placeholder("Enter password...")
              .echo_mode(:password)
              .validate(Huh::Validation.min_length(8)),

            # Select with options
            Huh.select
              .key("role")
              .title("Your role")
              .options(
                Huh.option("Developer", "dev"),
                Huh.option("Designer", "design"),
                Huh.option("Manager", "mgr")
              )
              .filtering(true),

            # Confirmation
            Huh.confirm
              .key("newsletter")
              .title("Subscribe to newsletter?")
              .affirmative("Yes!")
              .negative("No thanks")

          ).title("User Registration")
        ).with_theme(Huh::Themes.charm)
          .with_validate_on_submit(true)
      end

      def run
        errors = @form.run

        if errors.any?
          puts "Form errors:"
          errors.each { |e| puts "  - #{e.message}" }
          return nil
        end

        {
          name: @form.get("name"),
          email: @form.get("email"),
          role: @form.get("role"),
          newsletter: @form.get("newsletter")
        }
      end

      def values
        @form.to_h
      end
    end
  end
end

# Block-based DSL alternative
class AlternativeForm
  def self.build
    Huh::Form.new do |form|
      form.theme(Huh::Themes.charm)

      form.group do |group|
        group.title("Server Configuration")

        group.input do |input|
          input.key("host")
          input.title("Server hostname")
          input.placeholder("localhost")
          input.validate(Huh::Validation.not_empty)
        end

        group.input do |input|
          input.key("port")
          input.title("Port number")
          input.placeholder("8080")
          input.validate(Huh::Validation.all(
            Huh::Validation.not_empty,
            Huh::Validation.integer,
            Huh::Validation.range(1, 65535)
          ))
        end

        group.select do |select|
          select.key("protocol")
          select.title("Protocol")
          select.options("HTTP", "HTTPS")
        end
      end
    end
  end
end

# Standalone input example
def prompt_for_username
  username = Huh.input
    .title("Choose a username:")
    .placeholder("Enter username...")
    .suggestions(["admin", "user", "guest"])
    .validate(Huh::Validation.all(
      Huh::Validation.not_empty,
      Huh::Validation.min_length(3),
      Huh::Validation.max_length(20)
    ))
    .run

  puts "Hello, #{username}!"
  username
end
```

---

## Glamour Markdown Rendering

Rich text display with terminal formatting and custom styling:

```ruby
# lib/[app_name]/components/markdown_viewer.rb
# Query: /marcoroth/glamour-ruby "render markdown style theme width"

module MyApp
  module Components
    class MarkdownViewer
      def initialize(width: 80, style: "dark", emoji: true)
        @renderer = Glamour::Renderer.new(
          width: width,
          style: style,
          emoji: emoji,
          preserve_newlines: false
        )
      end

      def render(markdown_content)
        @renderer.render(markdown_content)
      end

      # Quick markdown rendering for simple content
      def self.render_simple(content, **options)
        Glamour.render(content, **options)
      end

      # Render help text with formatting
      def render_help_text
        help_content = <<~MD
          # Application Help :book:

          Welcome to the **TUI Application**! Here are the available commands:

          ## Navigation
          - `↑/↓` or `j/k` - Move up/down
          - `Enter` - Select item
          - `Tab` - Switch panels
          - `?` - Toggle this help

          ## Features
          - :rocket: Fast navigation
          - :art: Beautiful styling
          - :gear: Configurable options

          > **Tip**: Use `Ctrl+C` to quit at any time

          ```ruby
          # Example configuration
          config = {
            theme: "dark",
            width: 80,
            emoji: true
          }
          ```

          For more information, visit [our documentation](https://example.com).
        MD

        render(help_content)
      end

      # Display file content with syntax highlighting
      def render_file_content(file_path)
        return "File not found" unless File.exist?(file_path)

        content = File.read(file_path)
        extension = File.extname(file_path)

        # Wrap in code block for syntax highlighting
        formatted_content = case extension
        when '.rb'
          "```ruby\n#{content}\n```"
        when '.js'
          "```javascript\n#{content}\n```"
        when '.py'
          "```python\n#{content}\n```"
        when '.md'
          content  # Already markdown
        else
          "```\n#{content}\n```"
        end

        render(formatted_content)
      end

      # Display status messages with formatting
      def render_status(status, message)
        status_emoji = case status
        when :success then ":white_check_mark:"
        when :error then ":x:"
        when :warning then ":warning:"
        when :info then ":information_source:"
        else ":speech_balloon:"
        end

        formatted_message = "#{status_emoji} **#{status.to_s.capitalize}**: #{message}"
        render(formatted_message)
      end
    end

    # Custom style definition
    class DocumentStyle < Glamour::Style
      style :document do
        margin 1
        indent 2
      end

      style :h1 do
        prefix ">>> "
        color "99"
        bold true
        margin 1
      end

      style :h2 do
        prefix ">> "
        color "86"
        bold true
      end

      style :strong do
        bold true
        color "196"
      end

      style :emph do
        italic true
        color "226"
      end

      style :code do
        color "203"
        background_color "236"
      end

      style :code_block do
        margin 1
        chroma do
          keyword do
            color "170"
            bold true
          end
          string do
            color "113"
          end
          comment do
            color "240"
            italic true
          end
        end
      end

      style :list do
        margin 1
      end

      style :blockquote do
        margin 1
        indent 2
        color "245"
      end
    end

    # Usage with custom style
    class StyledMarkdownViewer
      def initialize
        @style = DocumentStyle
      end

      def render(content)
        @style.render(content, width: 70)
      end

      def render_with_options(content, **options)
        Glamour.render(content, style: @style, **options)
      end
    end
  end
end
```

---

## NTCharts Data Visualization

Terminal-based charts and data visualization components:

```ruby
# lib/[app_name]/components/metrics_dashboard.rb
# Query: /marcoroth/ntcharts-ruby "linechart timeseries barchart data visualization"

module MyApp
  module Components
    class MetricsDashboard
      def initialize
        @charts = {}
        @data_history = {}
      end

      # Time series chart for continuous metrics
      def create_time_series_chart(name, width: 60, height: 12)
        chart = Ntcharts::Timeserieslinechart.new(width, height)

        # Custom styling
        chart.style = Ntcharts::Style.new.foreground("39")  # Bright blue
        chart.axis_style = Ntcharts::Style.new.foreground("240")
        chart.label_style = Ntcharts::Style.new.foreground("245")

        @charts[name] = chart
        @data_history[name] = []
        chart
      end

      # Add data point to time series
      def add_metric_point(chart_name, value, timestamp = Time.now)
        chart = @charts[chart_name]
        return unless chart

        chart.push(timestamp, value)
        @data_history[chart_name] << { time: timestamp, value: value }

        # Keep last 100 points
        if @data_history[chart_name].length > 100
          @data_history[chart_name].shift
        end
      end

      # Multi-dataset time series (e.g., CPU, Memory, Disk)
      def create_system_metrics_chart
        chart = Ntcharts::Timeserieslinechart.new(70, 14)

        # Define styles for different metrics
        cpu_style = Ntcharts::Style.new.foreground("1")    # Red
        memory_style = Ntcharts::Style.new.foreground("3")  # Yellow
        disk_style = Ntcharts::Style.new.foreground("4")   # Blue

        chart.set_data_set_style("cpu", cpu_style)
        chart.set_data_set_style("memory", memory_style)
        chart.set_data_set_style("disk", disk_style)

        @charts["system_metrics"] = chart
        chart
      end

      # Update system metrics
      def update_system_metrics(cpu_percent, memory_percent, disk_percent)
        chart = @charts["system_metrics"]
        return unless chart

        timestamp = Time.now
        chart.push_data_set("cpu", timestamp, cpu_percent)
        chart.push_data_set("memory", timestamp, memory_percent)
        chart.push_data_set("disk", timestamp, disk_percent)
      end

      # Bar chart for categorical data
      def create_bar_chart(name, width: 50, height: 12)
        chart = Ntcharts::Barchart.new(width, height)
        @charts[name] = chart
        chart
      end

      # Update bar chart with new data
      def update_bar_chart(chart_name, data)
        chart = @charts[chart_name]
        return unless chart

        # Clear existing data
        chart.clear

        # Add new bars
        data.each do |item|
          label = item[:label]
          values = item[:values] || []

          chart.push(
            label: label,
            values: values.map { |v|
              {
                name: v[:name],
                value: v[:value],
                style: v[:style] || default_bar_style
              }
            }
          )
        end
      end

      # High-resolution line chart with braille characters
      def create_detailed_chart(name, width: 60, height: 15)
        chart = Ntcharts::Linechart.new(width, height, 0.0, 100.0, 0.0, 100.0)
        @charts[name] = chart
        chart
      end

      # Plot mathematical function
      def plot_function(chart_name, &function_block)
        chart = @charts[chart_name]
        return unless chart

        points = (0..100).map { |i|
          x = i.to_f
          y = function_block.call(x)
          [x, y]
        }

        # Draw connected line with braille characters
        points.each_cons(2) do |(x1, y1), (x2, y2)|
          chart.draw_braille_line(x1, y1, x2, y2)
        end

        chart.draw_axes
      end

      # Render all charts
      def render_dashboard
        output = []

        @charts.each do |name, chart|
          output << "=== #{name.to_s.tr('_', ' ').upcase} ==="

          case chart
          when Ntcharts::Timeserieslinechart
            output << chart.render_braille  # High resolution
          when Ntcharts::Barchart
            output << chart.render
          when Ntcharts::Linechart
            output << chart.view
          end

          output << ""  # Empty line between charts
        end

        output.join("\n")
      end

      # Get chart statistics
      def get_chart_stats(chart_name)
        chart = @charts[chart_name]
        return {} unless chart.respond_to?(:min_y)

        {
          min_x: chart.min_x,
          max_x: chart.max_x,
          min_y: chart.min_y,
          max_y: chart.max_y,
          data_points: @data_history[chart_name]&.length || 0
        }
      end

      private

      def default_bar_style
        Ntcharts::Style.new.foreground("2").background("2")  # Green
      end
    end

    # Real-time metrics collector
    class RealtimeMetrics
      def initialize(dashboard)
        @dashboard = dashboard
        @running = false
      end

      def start_collection
        @running = true

        # Create charts
        @dashboard.create_time_series_chart("response_time", width: 60, height: 10)
        @dashboard.create_system_metrics_chart

        # Simulate real-time data collection
        Thread.new do
          while @running
            # Simulate response time data
            response_time = 100 + Math.sin(Time.now.to_f * 0.1) * 50 + rand * 20
            @dashboard.add_metric_point("response_time", response_time)

            # Simulate system metrics
            cpu = 20 + Math.sin(Time.now.to_f * 0.05) * 15 + rand * 10
            memory = 50 + Math.sin(Time.now.to_f * 0.03) * 20 + rand * 5
            disk = 30 + rand * 5

            @dashboard.update_system_metrics(cpu, memory, disk)

            sleep 1
          end
        end
      end

      def stop_collection
        @running = false
      end
    end
  end
end

# Example usage
dashboard = MyApp::Components::MetricsDashboard.new
metrics = MyApp::Components::RealtimeMetrics.new(dashboard)

# Start collecting metrics
metrics.start_collection

# Display dashboard
loop do
  system("clear")
  puts dashboard.render_dashboard
  sleep 2
end
```

---

## Integrated Form and Display Example

Combining Huh forms, Glamour rendering, and NTCharts visualization:

```ruby
# lib/[app_name]/apps/analytics_configurator.rb
# Complete application integrating all components

module MyApp
  module Apps
    class AnalyticsConfigurator
      def initialize
        @config = {}
        @dashboard = Components::MetricsDashboard.new
        @viewer = Components::MarkdownViewer.new(width: 80)
      end

      def run
        show_welcome
        collect_configuration
        setup_dashboard
        display_results
      end

      private

      def show_welcome
        welcome_text = <<~MD
          # Analytics Dashboard Configurator :bar_chart:

          Welcome to the **Analytics Dashboard Setup**!

          This wizard will help you configure your monitoring dashboard
          with the following features:

          - :gear: **Data Source Configuration**
          - :chart_with_upwards_trend: **Chart Selection**
          - :art: **Styling Options**
          - :rocket: **Real-time Updates**

          Let's get started!
        MD

        puts @viewer.render(welcome_text)
        puts "\nPress Enter to continue..."
        gets
      end

      def collect_configuration
        # Data source configuration
        data_form = Huh.form(
          Huh.group(
            Huh.input
              .key("host")
              .title("Data source host")
              .placeholder("localhost")
              .validate(Huh::Validation.not_empty),

            Huh.input
              .key("port")
              .title("Port")
              .placeholder("8080")
              .validate(Huh::Validation.all(
                Huh::Validation.integer,
                Huh::Validation.range(1, 65535)
              )),

            Huh.input
              .key("api_key")
              .title("API Key")
              .echo_mode(:password)
              .validate(Huh::Validation.min_length(10))

          ).title("Data Source Configuration")
        ).with_theme(Huh::Themes.charm)

        data_form.run
        @config[:data_source] = data_form.to_h

        # Chart selection
        chart_form = Huh.form(
          Huh.group(
            Huh.select
              .key("chart_type")
              .title("Primary chart type")
              .options(
                Huh.option("Time Series", "timeseries"),
                Huh.option("Bar Chart", "bar"),
                Huh.option("Line Chart", "line")
              ),

            Huh.input
              .key("update_interval")
              .title("Update interval (seconds)")
              .placeholder("5")
              .validate(Huh::Validation.all(
                Huh::Validation.integer,
                Huh::Validation.range(1, 3600)
              )),

            Huh.confirm
              .key("enable_alerts")
              .title("Enable threshold alerts?")
              .affirmative("Yes")
              .negative("No")

          ).title("Chart Configuration")
        ).with_theme(Huh::Themes.charm)

        chart_form.run
        @config[:charts] = chart_form.to_h
      end

      def setup_dashboard
        puts @viewer.render_status(:info, "Setting up dashboard with your configuration...")

        case @config[:charts]["chart_type"]
        when "timeseries"
          @dashboard.create_time_series_chart("main_metric")

          # Add some sample data
          base_time = Time.now - 300  # 5 minutes ago
          (0..60).each do |i|
            timestamp = base_time + (i * 5)
            value = 50 + Math.sin(i * 0.2) * 20 + rand * 10
            @dashboard.add_metric_point("main_metric", value, timestamp)
          end

        when "bar"
          @dashboard.create_bar_chart("main_metric")
          sample_data = [
            {
              label: "Service A",
              values: [
                { name: "Requests", value: 150, style: Ntcharts::Style.new.foreground("2") },
                { name: "Errors", value: 5, style: Ntcharts::Style.new.foreground("1") }
              ]
            },
            {
              label: "Service B",
              values: [
                { name: "Requests", value: 200, style: Ntcharts::Style.new.foreground("2") },
                { name: "Errors", value: 12, style: Ntcharts::Style.new.foreground("1") }
              ]
            }
          ]
          @dashboard.update_bar_chart("main_metric", sample_data)

        when "line"
          @dashboard.create_detailed_chart("main_metric")
          @dashboard.plot_function("main_metric") { |x| Math.sin(x * 0.1) * 40 + 50 }
        end

        sleep 1  # Simulate setup time
      end

      def display_results
        config_summary = <<~MD
          # Configuration Complete! :white_check_mark:

          ## Data Source
          - **Host**: #{@config[:data_source]["host"]}
          - **Port**: #{@config[:data_source]["port"]}
          - **API Key**: #{'*' * @config[:data_source]["api_key"].length}

          ## Chart Settings
          - **Type**: #{@config[:charts]["chart_type"].capitalize}
          - **Update Interval**: #{@config[:charts]["update_interval"]} seconds
          - **Alerts**: #{@config[:charts]["enable_alerts"] ? "Enabled" : "Disabled"}

          ## Live Dashboard

          Your dashboard is now configured and running below:
        MD

        loop do
          system("clear")
          puts @viewer.render(config_summary)
          puts "\n" + "="*80 + "\n"
          puts @dashboard.render_dashboard
          puts "\n" + "="*80
          puts "Press Ctrl+C to exit"

          sleep(@config[:charts]["update_interval"].to_i)

          # Simulate new data
          if @config[:charts]["chart_type"] == "timeseries"
            value = 50 + Math.sin(Time.now.to_f * 0.1) * 20 + rand * 15
            @dashboard.add_metric_point("main_metric", value)
          end
        end
      end
    end
  end
end
```

---

## Harmonica Spring Animations

Physics-based animations for smooth UI transitions and natural motion:

```ruby
# lib/[app_name]/components/animated_list.rb
# Query: /marcoroth/harmonica-ruby "spring animation physics smooth scrolling"

module MyApp
  module Components
    class AnimatedList
      def initialize(items)
        @items = items
        @scroll_position = 0.0
        @scroll_velocity = 0.0
        @target_scroll = 0.0
        @visible_count = 10

        # Critically damped spring for smooth, no-bounce scrolling
        @scroll_spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(60),
          angular_frequency: 5.0,
          damping_ratio: 1.0  # Critically damped - no overshoot
        )
      end

      def scroll_up(amount = 1)
        @target_scroll = [@target_scroll - amount, 0].max
      end

      def scroll_down(amount = 1)
        max_scroll = [@items.length - @visible_count, 0].max
        @target_scroll = [@target_scroll + amount, max_scroll].min
      end

      def scroll_to(position)
        max_scroll = [@items.length - @visible_count, 0].max
        @target_scroll = [[position, 0].max, max_scroll].min
      end

      def update
        # Update spring physics
        @scroll_position, @scroll_velocity = @scroll_spring.update(
          @scroll_position,
          @scroll_velocity,
          @target_scroll
        )
      end

      def render
        visible_start = @scroll_position.floor
        visible_end = [visible_start + @visible_count, @items.length].min
        visible_items = @items[visible_start...visible_end] || []

        output = []
        visible_items.each_with_index do |item, i|
          line_number = visible_start + i + 1
          prefix = line_number == (@target_scroll + 1).floor ? "▶ " : "  "
          output << "#{prefix}#{line_number}. #{item}"
        end

        # Add scroll indicator
        if @items.length > @visible_count
          scroll_percent = (@scroll_position / [@items.length - @visible_count, 1].max * 100).round(1)
          output << ""
          output << "Scroll: #{scroll_percent}% (#{@scroll_position.round(1)}/#{@items.length - @visible_count})"
        end

        output.join("\n")
      end

      def at_rest?
        (@scroll_position - @target_scroll).abs < 0.01 && @scroll_velocity.abs < 0.01
      end
    end

    # Animated progress bar with spring physics
    class AnimatedProgress
      def initialize(total = 100, width = 50)
        @total = total
        @width = width
        @current_value = 0.0
        @velocity = 0.0
        @target_value = 0.0

        # Bouncy spring for satisfying progress animations
        @progress_spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(60),
          angular_frequency: 6.0,
          damping_ratio: 0.3  # Bouncy for visual feedback
        )
      end

      def set_progress(value)
        @target_value = [[value, 0].max, @total].min
      end

      def increment(amount = 1)
        set_progress(@target_value + amount)
      end

      def update
        @current_value, @velocity = @progress_spring.update(
          @current_value,
          @velocity,
          @target_value
        )
      end

      def render
        progress_ratio = @current_value / @total
        filled_width = (progress_ratio * @width).round

        bar = "#" * filled_width
        empty = " " * (@width - filled_width)
        percentage = (progress_ratio * 100).round(1)

        "[#{bar}#{empty}] #{percentage}% (#{@current_value.round(1)}/#{@total})"
      end

      def complete?
        (@current_value - @target_value).abs < 0.01
      end
    end

    # Animated value transitions for counters and metrics
    class AnimatedCounter
      def initialize(initial_value = 0, decimal_places = 0)
        @current_value = initial_value.to_f
        @velocity = 0.0
        @target_value = initial_value.to_f
        @decimal_places = decimal_places

        # Smooth spring for counter animations
        @counter_spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(60),
          angular_frequency: 4.0,
          damping_ratio: 0.8  # Slightly underdamped for gentle overshoot
        )
      end

      def set_value(value)
        @target_value = value.to_f
      end

      def update
        @current_value, @velocity = @counter_spring.update(
          @current_value,
          @velocity,
          @target_value
        )
      end

      def render(prefix: "", suffix: "")
        formatted_value = @current_value.round(@decimal_places)
        "#{prefix}#{formatted_value}#{suffix}"
      end

      def at_target?
        (@current_value - @target_value).abs < (0.1 ** @decimal_places)
      end
    end

    # Panel slide transitions
    class AnimatedPanel
      def initialize(content, width = 40)
        @content = content
        @width = width
        @x_position = -width.to_f  # Start off-screen
        @velocity = 0.0
        @target_x = -width.to_f
        @visible = false

        # Fast, smooth slide animation
        @slide_spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(60),
          angular_frequency: 8.0,
          damping_ratio: 1.2  # Slightly overdamped for no overshoot
        )
      end

      def show
        @visible = true
        @target_x = 0.0
      end

      def hide
        @visible = false
        @target_x = -@width.to_f
      end

      def toggle
        @visible ? hide : show
      end

      def update
        @x_position, @velocity = @slide_spring.update(
          @x_position,
          @velocity,
          @target_x
        )
      end

      def render
        return "" if @x_position <= -@width

        # Calculate visible portion
        visible_width = [@width + @x_position.floor, 0].max
        return "" if visible_width <= 0

        # Render visible content
        lines = @content.split("\n")
        visible_lines = lines.map do |line|
          if @x_position >= 0
            line.ljust(@width)[0, visible_width]
          else
            offset = -@x_position.floor
            line_content = line[offset..-1] || ""
            line_content.ljust(@width - offset)[0, visible_width]
          end
        end

        visible_lines.join("\n")
      end

      def fully_visible?
        @x_position >= -0.01 && @visible
      end

      def fully_hidden?
        @x_position <= -@width + 0.01 && !@visible
      end
    end

    # Smooth state transitions for UI elements
    class AnimatedState
      def initialize(initial_state = 0.0)
        @current_state = initial_state
        @velocity = 0.0
        @target_state = initial_state
        @states = {}

        @state_spring = Harmonica::Spring.new(
          delta_time: Harmonica.fps(60),
          angular_frequency: 6.0,
          damping_ratio: 0.7
        )
      end

      def define_state(name, value)
        @states[name] = value.to_f
      end

      def transition_to(state_name)
        return unless @states.key?(state_name)
        @target_state = @states[state_name]
      end

      def set_direct(value)
        @target_state = value.to_f
      end

      def update
        @current_state, @velocity = @state_spring.update(
          @current_state,
          @velocity,
          @target_state
        )
      end

      def interpolate(min_val, max_val)
        ratio = [@current_state, 0].max
        ratio = [ratio, 1].min
        min_val + (max_val - min_val) * ratio
      end

      def current_value
        @current_state
      end

      def at_rest?
        (@current_state - @target_state).abs < 0.01
      end
    end
  end
end

# Usage examples:

# Animated scrollable list
list = MyApp::Components::AnimatedList.new((1..100).map { |i| "Item #{i}" })

# Animation loop
Thread.new do
  loop do
    list.update
    sleep(1.0 / 60)  # 60 FPS
  end
end

# Progress bar with spring animation
progress = MyApp::Components::AnimatedProgress.new(100, 50)
progress.set_progress(75)

# Counter with smooth value changes
counter = MyApp::Components::AnimatedCounter.new(0, 2)
counter.set_value(42.56)

# Panel slide animation
panel_content = <<~CONTENT
  Settings Panel
  ==============

  Option 1: Value A
  Option 2: Value B
  Option 3: Value C
CONTENT

panel = MyApp::Components::AnimatedPanel.new(panel_content, 30)
panel.show  # Slide in from left
```

---

## Animated TUI Application Example

Complete application integrating harmonica animations with other components:

```ruby
# lib/[app_name]/apps/animated_dashboard.rb
# Complete animated TUI combining multiple spring animations

module MyApp
  module Apps
    class AnimatedDashboard
      include Bubbletea::Model

      def initialize
        @mode = :list
        @transition_state = Components::AnimatedState.new(0.0)
        @transition_state.define_state(:list, 0.0)
        @transition_state.define_state(:details, 1.0)

        # File list with smooth scrolling
        @file_list = Components::AnimatedList.new(
          Dir.glob("**/*.rb").first(50)
        )

        # Progress tracking
        @loading_progress = Components::AnimatedProgress.new(100, 60)
        @file_counter = Components::AnimatedCounter.new(0, 0)

        # Side panel for details
        @details_panel = Components::AnimatedPanel.new(
          generate_details_content, 40
        )

        # Metrics with animated values
        @metrics = {
          cpu: Components::AnimatedCounter.new(0, 1),
          memory: Components::AnimatedCounter.new(0, 1),
          files: Components::AnimatedCounter.new(0, 0)
        }

        @last_update = Time.now
        start_metrics_simulation
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "q"
            return [self, Bubbletea.quit]
          when "up", "k"
            @file_list.scroll_up
          when "down", "j"
            @file_list.scroll_down
          when "tab"
            toggle_mode
          when "space"
            simulate_loading
          when "r"
            refresh_data
          end
        when :animation_tick
          update_animations
        end

        [self, Bubbletea.every(16_000_000)] # ~60 FPS
      end

      def view
        # Update all animations
        update_animations

        header = render_header
        main_content = render_main_content
        footer = render_footer

        Lipgloss.join_vertical(
          Lipgloss::Align::LEFT,
          header,
          main_content,
          footer
        )
      end

      private

      def toggle_mode
        case @mode
        when :list
          @mode = :details
          @transition_state.transition_to(:details)
          @details_panel.show
        when :details
          @mode = :list
          @transition_state.transition_to(:list)
          @details_panel.hide
        end
      end

      def update_animations
        @file_list.update
        @loading_progress.update
        @file_counter.update
        @details_panel.update
        @transition_state.update
        @metrics.each { |_, metric| metric.update }
      end

      def render_header
        cpu_display = @metrics[:cpu].render(prefix: "CPU: ", suffix: "%")
        memory_display = @metrics[:memory].render(prefix: "MEM: ", suffix: "%")
        files_display = @metrics[:files].render(prefix: "Files: ")

        header_text = "Animated Dashboard │ #{cpu_display} │ #{memory_display} │ #{files_display}"
        Styles::HEADER.render(header_text)
      end

      def render_main_content
        list_content = @file_list.render

        if @mode == :details && @details_panel.fully_visible?
          # Show side-by-side layout
          main_pane = Styles::MAIN_PANE.render(list_content)
          details_pane = Styles::SIDEBAR.render(@details_panel.render)

          Lipgloss.join_horizontal(
            Lipgloss::Align::TOP,
            main_pane,
            details_pane
          )
        else
          # Show just the list with potential panel overlay
          content = Styles::MAIN_PANE.render(list_content)

          if @details_panel.x_position > -@details_panel.width
            # Overlay the sliding panel
            panel_overlay = @details_panel.render
            unless panel_overlay.empty?
              content = overlay_content(content, panel_overlay)
            end
          end

          content
        end
      end

      def render_footer
        progress_bar = @loading_progress.render

        controls = [
          "↑/↓ Navigate",
          "Tab Switch Mode",
          "Space Load",
          "R Refresh",
          "Q Quit"
        ].join(" │ ")

        footer_text = "#{progress_bar}\n#{controls}"
        Styles::STATUS_BAR.render(footer_text)
      end

      def simulate_loading
        @loading_progress.set_progress(0)

        Thread.new do
          (0..100).each do |i|
            @loading_progress.set_progress(i)
            sleep(0.02)
          end
        end
      end

      def refresh_data
        # Simulate data refresh with animated counters
        new_files = Dir.glob("**/*.rb").length
        @file_counter.set_value(new_files)
        @metrics[:files].set_value(new_files)

        # Update file list
        @file_list = Components::AnimatedList.new(
          Dir.glob("**/*.{rb,js,py}").first(50)
        )
      end

      def start_metrics_simulation
        Thread.new do
          loop do
            # Simulate changing system metrics
            cpu = 20 + Math.sin(Time.now.to_f * 0.1) * 15 + rand * 10
            memory = 60 + Math.sin(Time.now.to_f * 0.05) * 20 + rand * 5

            @metrics[:cpu].set_value(cpu)
            @metrics[:memory].set_value(memory)

            sleep(0.5)
          end
        end
      end

      def generate_details_content
        <<~DETAILS
          File Details
          ============

          Selected: #{@file_list.current_selection || 'None'}

          Properties:
          - Size: 2.4 KB
          - Modified: 2 hours ago
          - Lines: 87

          Actions:
          - Edit (E)
          - View (V)
          - Delete (D)

          Press Tab to close
        DETAILS
      end

      def overlay_content(base, overlay)
        # Simple overlay implementation
        base_lines = base.split("\n")
        overlay_lines = overlay.split("\n")

        overlay_lines.each_with_index do |overlay_line, i|
          next if overlay_line.strip.empty?

          if i < base_lines.length
            base_lines[i] = overlay_line
          else
            base_lines << overlay_line
          end
        end

        base_lines.join("\n")
      end
    end
  end
end

# Launch animated dashboard
Bubbletea.run(MyApp::Apps::AnimatedDashboard.new)
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
