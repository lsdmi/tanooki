# frozen_string_literal: true

module Search
  # Turbo frame and stream rendering for paginated search sections.
  module IndexTurboStreams
    extend ActiveSupport::Concern

    private

    def render_search_turbo_frame
      case turbo_frame_request_id
      when 'fictions-section'
        render partial: 'search/fictions_section', locals: fictions_section_locals
      when 'results-section'
        render partial: 'search/results_section', locals: results_section_locals
      when 'videos-section'
        render partial: 'search/videos_section', locals: videos_section_locals
      end
    end

    def render_search_turbo_stream
      section = params[:section]
      target, partial, locals = search_turbo_stream_section(section)
      return unless target

      render turbo_stream: search_section_stream(target, partial, locals)
    end

    def search_turbo_stream_section(section)
      case section
      when 'fictions' then ['fictions-section', 'search/fictions_section', fictions_section_locals]
      when 'results' then ['results-section', 'search/results_section', results_section_locals]
      when 'videos' then ['videos-section', 'search/videos_section', videos_section_locals]
      end
    end

    def fictions_section_locals
      { fictions: @fictions, pagy_fictions: @pagy_fictions }
    end

    def results_section_locals
      { results: @results, pagy_results: @pagy_results }
    end

    def videos_section_locals
      { videos: @videos, pagy_videos: @pagy_videos }
    end

    def search_section_stream(target, partial, locals)
      turbo_stream.replace(target, partial: partial, locals: locals)
    end
  end
end
