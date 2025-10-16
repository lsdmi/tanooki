# frozen_string_literal: true

module PagyHelper
  include Pagy::Frontend

  def pagy_nav_with_turbo_frame(pagy, frame_id = 'tab-content')
    pagy_nav(pagy).gsub('<a ', "<a data-turbo-frame=\"#{frame_id}\" data-turbo-stream=\"true\" ")
  end

  def pagy_nav_buttons(pagy, pagy_id: 'pagy', frame_id: nil, aria_label: 'Сторінок')
    html = "<nav id=\"#{pagy_id}\" class=\"pagy nav\" aria-label=\"#{aria_label}\">"

    html << pagy_prev_button(pagy, frame_id)
    pagy.series.each do |item|
      html << case item
              when Integer then pagy_page_button(item, pagy, frame_id)
              when String  then if item.to_i.to_s == item
                                  pagy_page_button(item.to_i, pagy,
                                                   frame_id)
                                else
                                  pagy_gap_span(item)
                                end
              when :gap    then pagy_gap_span
              end
    end
    html << pagy_next_button(pagy, frame_id)

    html << '</nav>'
    html
  end

  private

  def pagy_prev_button(pagy, frame_id)
    if pagy.prev
      form_options = frame_id ? { data: { turbo_frame: frame_id } } : {}
      button_to(
        '&lt;'.html_safe,
        request.path,
        method: :get,
        params: { page: pagy.prev },
        class: 'pagy-prev',
        'aria-label': 'Назад',
        form: form_options
      )
    else
      %(<button role="link" aria-disabled="true" aria-label="Назад" class="pagy-prev disabled">&lt;</button>)
    end
  end

  def pagy_next_button(pagy, frame_id)
    if pagy.next
      form_options = frame_id ? { data: { turbo_frame: frame_id } } : {}
      button_to(
        '&gt;'.html_safe,
        request.path,
        method: :get,
        params: { page: pagy.next },
        class: 'pagy-next',
        'aria-label': 'Далі',
        form: form_options
      )
    else
      %(<button role="link" aria-disabled="true" aria-label="Далі" class="pagy-next disabled">&gt;</button>)
    end
  end

  def pagy_page_button(page, pagy, frame_id)
    if page == pagy.page
      %(<button role="link" aria-disabled="true" aria-current="page" class="current">#{page}</button>)
    else
      form_options = frame_id ? { data: { turbo_frame: frame_id } } : {}
      button_to(
        page.to_s,
        request.path,
        method: :get,
        params: { page: page },
        form: form_options
      )
    end
  end

  def pagy_gap_span(text = '…')
    %(<button role="link" aria-disabled="true" class="gap">#{text}</button>)
  end
end
