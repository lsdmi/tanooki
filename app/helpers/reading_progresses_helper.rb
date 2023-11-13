# frozen_string_literal: true

module ReadingProgressesHelper
  DESCRIPTION = 'Твір буде прибрано із читальні, тож ви не зможете відслідковувати нові розділи. Продовжити?'
  MESSAGE = 'Певні, що прагнете прибрати твір із читальні?'

  def sweetalert_options(reading_progress)
    {
      description: DESCRIPTION,
      message: MESSAGE,
      tag_id: "progress_item-#{reading_progress.id}",
      url: destroy_reading_progress_path(reading_progress)
    }
  end
end
