# frozen_string_literal: true

require 'test_helper'

class RawPaletteClassesTest < ActiveSupport::TestCase
  RAW_PALETTE_PATTERN = /
    (?<![\w-])(?:[a-z-]+:)*!?
    (?:text|bg|border(?:-[tblrxy])?|divide|ring|ring-offset|outline|from|via|to
      |placeholder|fill|stroke|decoration|caret|accent)
    -(?:gray|stone|slate|zinc|neutral|cyan|rose)-\d{2,3}\b
  /x
  SCAN_ROOTS = %w[app/views app/helpers app/components app/presenters app/javascript].freeze
  SKIP_PATHS = %r{\Aapp/views/(?:layouts/mailer|user_mailer|users/mailer|pwa)}

  test 'neutral and brand colors come from design tokens' do
    offenders = SCAN_ROOTS.flat_map { |root| raw_palette_lines(root) }

    assert_empty offenders,
                 'Raw neutral / brand palette classes (use a token from docs/DESIGN_SYSTEM.md, ' \
                 "or add the no-op class token-raw for intentional raw colors):\n#{offenders.join("\n")}"
  end

  private

  def raw_palette_lines(root)
    Rails.root.glob("#{root}/**/*.{erb,rb,js}").flat_map do |path|
      relative_path = path.relative_path_from(Rails.root).to_s
      next [] if relative_path.match?(SKIP_PATHS)

      path.each_line.with_index(1).filter_map do |line, line_number|
        next if line.include?('token-raw')

        match = line[RAW_PALETTE_PATTERN] or next
        "  #{relative_path}:#{line_number} #{match}"
      end
    end
  end
end
