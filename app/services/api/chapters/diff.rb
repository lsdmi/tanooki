# frozen_string_literal: true

require 'diff/lcs'

module Api
  module Chapters
    # Paragraph-level diff between a stored revision and the chapter as it is now.
    class Diff
      def self.call(chapter, revision)
        before = ::Chapters::Paragraphs.list(revision.body).pluck(:markdown)
        after = ::Chapters::Paragraphs.list(chapter.content_html).pluck(:markdown)
        ::Diff::LCS.sdiff(before, after).map { |change| entry(change) }
      end

      def self.entry(change)
        case change.action
        when '!' then { change: 'changed', old: change.old_element, new: change.new_element }
        when '-' then { change: 'removed', old: change.old_element }
        when '+' then { change: 'added', new: change.new_element }
        else { change: 'same', text: change.new_element }
        end
      end

      private_class_method :entry
    end
  end
end
