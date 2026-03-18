# frozen_string_literal: true

module AppName
  module Styles
    HEADER = Lipgloss::Style.new
      .bold(true)
      .foreground(Lipgloss::Color.new("#FFFFFF"))
      .background(Lipgloss::Color.new("#5C5C5C"))
      .padding(0, 1)

    STATUS_BAR = Lipgloss::Style.new
      .foreground(Lipgloss::Color.new("#AAAAAA"))
      .padding(0, 1)

    PANEL = Lipgloss::Style.new
      .border(:rounded)
      .border_foreground(Lipgloss::Color.new("#444444"))
      .padding(0, 1)

    ACTIVE_PANEL = Lipgloss::Style.new
      .border(:rounded)
      .border_foreground(Lipgloss::Color.new("#7DCFFF"))
      .padding(0, 1)

    SIDEBAR = Lipgloss::Style.new
      .width(30)
      .border(:rounded)
      .padding(0, 1)
  end
end
