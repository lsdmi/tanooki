# frozen_string_literal: true

module Pokemons
  class PanelComponentPreview < ViewComponent::Preview
    # @label Title, subtitle and action
    def default
      render_with_template(template: 'pokemons/panel_component_preview/default')
    end

    # @label Title only
    def title_only
      render(PanelComponent.new(title: 'Остання сутичка')) do
        tag.p('Ваші покемони рвуться в бій!', class: 'text-sm/5 text-fg-secondary')
      end
    end
  end
end
