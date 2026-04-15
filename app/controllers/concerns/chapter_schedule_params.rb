# frozen_string_literal: true

# Merges split date/time form fields into Chapter#published_at (when the chapter becomes visible to everyone).
module ChapterScheduleParams
  extend ActiveSupport::Concern

  private

  def schedule_error_message
    'Вкажіть і дату, і час, або залиште обидва поля порожніми'
  end

  def render_new_with_schedule_error
    @chapter.errors.add(:published_at, schedule_error_message)
    render 'chapters/new', status: :unprocessable_content
  end

  def render_edit_with_schedule_error
    @chapter.assign_attributes(chapter_params)
    @chapter.errors.add(:published_at, schedule_error_message)
    render 'chapters/edit', status: :unprocessable_content
  end

  def merge_published_at_from_schedule_fields(permitted)
    date_part = permitted.delete(:published_at_date).presence
    time_part = permitted.delete(:published_at_time).presence
    permitted[:published_at] =
      date_part && time_part ? Time.zone.parse("#{date_part} #{time_part}") : nil
    permitted
  end

  def published_at_schedule_invalid?
    ch = params[:chapter]
    return false unless ch

    d = ch[:published_at_date].presence
    t = ch[:published_at_time].presence
    d.present? ^ t.present?
  end
end
