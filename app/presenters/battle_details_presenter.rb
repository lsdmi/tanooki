# frozen_string_literal: true

# Assembles trusted battle-log HTML fragments into the grid layout for the battle UI.
class BattleDetailsPresenter
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  def initialize(start_message, outcome_blocks, conclusion_message)
    @start_message = start_message
    @outcome_blocks = outcome_blocks
    @conclusion_message = conclusion_message
  end

  def render
    grid_content, conclusion_html = prepare_grid_content

    safe_join(
      [
        @start_message,
        tag.div(class: 'grid grid-cols-1 sm:grid-cols-2 gap-3 mb-2') { safe_join(grid_content) },
        conclusion_html
      ].compact
    )
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
