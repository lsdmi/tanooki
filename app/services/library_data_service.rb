# frozen_string_literal: true

class LibraryDataService
  def initialize(user, section, page = 1)
    @user = user
    @section = section
    @page = page
  end

  def call
    generate_library_data
  end

  private

  def generate_library_data
    history = reading_history
    history_presenter = ReadingHistoryPresenter.new(history)
    section_data = history_presenter.section(@section)

    build_data_hash(history, history_presenter, section_data)
  end

  def build_data_hash(history, history_presenter, section_data)
    {
      section: @section,
      history: history,
      history_presenter: history_presenter,
      section_data: section_data
    }
  end

  def reading_history
    Rails.cache.fetch("user:#{@user.id}:reading_history", expires_in: 5.minutes) do
      ReadingHistoryFetcher.new(@user).call
    end
  end
end
