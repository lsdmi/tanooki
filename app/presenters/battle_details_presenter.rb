# frozen_string_literal: true

class BattleDetailsPresenter
  def initialize(start_message, outcome_blocks, conclusion_message)
    @start_message = start_message
    @outcome_blocks = outcome_blocks
    @conclusion_message = conclusion_message
  end

  def render
    grid_content, conclusion_html = prepare_grid_content

    <<~HTML.html_safe
      #{@start_message}
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-2">
        #{grid_content.join}
      </div>
      #{conclusion_html}
    HTML
  end

  private

  def prepare_grid_content
    grid_content = @outcome_blocks.dup
    if grid_content.size.odd?
      grid_content << @conclusion_message
      [grid_content, '']
    else
      [grid_content, @conclusion_message]
    end
  end
end
