# frozen_string_literal: true

module Chapters
  # Moves inline base64 images out of a chapter body into chapter image storage and
  # links them by URL. A corrupt image stays inline and is logged.
  #
  # The body is rewritten with a raw UPDATE guarded by the updated_at read at the start,
  # so an edit saved while this ran is never overwritten; that save queued its own run,
  # and blobs stored here stay unattached for orphan cleanup.
  class ExtractInlineImages
    Result = Data.define(:status, :extracted, :failed, :before_bytes, :after_bytes)
    DATA_URI_SRC = %r{\ssrc\s*=\s*(["'])data:image/[a-z0-9.+-]+[^,"']*;base64,}i

    def self.call(chapter_id)
      new(chapter_id).call
    end

    def initialize(chapter_id)
      @chapter = Chapter.find(chapter_id)
      @blobs = []
      @failed = 0
    end

    def call
      rich_text = @chapter.rich_text_content
      html = rich_text&.read_attribute_before_type_cast(:body).to_s
      return result(:unchanged, html, html) unless html.include?(ContentLimits::BASE64_MARKER)

      output = rewrite(html)
      return result(:unchanged, html, html) if @blobs.empty?

      status = persist(rich_text, output) ? :extracted : :conflict
      result(status, html, output)
    end

    private

    def rewrite(html)
      output = +''
      pos = 0
      while (tag_start = html.index('<img', pos)) && (tag_end = html.index('>', tag_start))
        output << html[pos...tag_start] << rewrite_tag(html, tag_start, tag_end)
        pos = tag_end + 1
      end
      output << html[pos..] if pos < html.length
      output
    end

    def rewrite_tag(html, tag_start, tag_end)
      value_start, payload_start, value_end = data_uri_bounds(html, tag_start, tag_end)
      blob = value_start && store(html, payload_start, value_end)
      return html[tag_start..tag_end] unless blob

      html[tag_start...value_start] + Images.url_for(blob) + html[value_end..tag_end]
    end

    def data_uri_bounds(html, tag_start, tag_end)
      match = DATA_URI_SRC.match(html, tag_start)
      return unless match && match.end(0) <= tag_end

      value_end = html.index(match[1], match.end(0))
      [match.begin(1) + 1, match.end(0), value_end] if value_end && value_end <= tag_end
    end

    def store(html, payload_start, payload_end)
      image = decode_and_process(html, payload_start, payload_end)
      return failure(payload_start) unless image

      blob = Images.store!(image)
      @blobs << blob
      blob
    ensure
      GC.start(full_mark: false)
    end

    def decode_and_process(html, payload_start, payload_end)
      Tempfile.create(%w[chapter_image .bin], binmode: true) do |file|
        Books::EpubDataUriBase64Io.write_range(html, payload_start, payload_end, file)
        file.flush
        ImageProcessor.call(file.path)
      end
    end

    def failure(offset)
      @failed += 1
      Rails.logger.warn("[ChapterImages] chapter=#{@chapter.id} image at #{offset} is unreadable; left inline")
      nil
    end

    def persist(rich_text, html)
      ActionText::RichText.transaction do
        now = Time.current
        raise ActiveRecord::Rollback if update_body(rich_text, html, now).zero?

        @blobs.each { |blob| @chapter.images_attachments.create!(blob:) }
        connection.update("UPDATE chapters SET updated_at = #{connection.quote(now)} WHERE id = #{@chapter.id.to_i}")
        true
      end
    end

    def update_body(rich_text, html, now)
      connection.update(<<~SQL.squish)
        UPDATE action_text_rich_texts
        SET body = #{connection.quote(html)}, updated_at = #{connection.quote(now)}
        WHERE id = #{Integer(rich_text.id)} AND updated_at = #{connection.quote(rich_text.updated_at)}
      SQL
    end

    def connection
      ActionText::RichText.lease_connection
    end

    def result(status, before, after)
      Result.new(status:, extracted: status == :extracted ? @blobs.size : 0,
                 failed: @failed, before_bytes: before.bytesize, after_bytes: after.bytesize)
    end
  end
end
