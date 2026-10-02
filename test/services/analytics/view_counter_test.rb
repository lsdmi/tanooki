# frozen_string_literal: true

require 'test_helper'

module Analytics
  class ViewCounterTest < ActiveSupport::TestCase
    setup do
      @counter = ViewCounter.new(background: false)
    end

    test 'writes the summed views for every show-page model' do
      records = [bookshelves(:one), chapters(:one), fictions(:one), publications(:tale_approved_one),
                 publications(:tale_created_one), youtube_videos(:one)]
      before = records.index_with { |record| record.views.to_i }

      records.each { |record| 2.times { @counter.add(record) } }
      @counter.flush

      records.each { |record| assert_equal before[record] + 2, record.reload.views, record.class.name }
    end

    test 'one update per model, nothing when there is nothing to write' do
      @counter.add(fictions(:one))
      @counter.add(fictions(:two))
      @counter.add(chapters(:one))

      assert_queries_count(2) { @counter.flush }
      assert_no_queries { @counter.flush }
    end

    test 'skips soft-deleted records and models it does not count' do
      fiction = fictions(:one)
      views = fiction.views
      fiction.destroy

      @counter.add(fiction)
      @counter.add(users(:user_one))
      @counter.flush

      assert_equal views, Fiction.unscoped.find(fiction.id).views
      assert_empty @counter.pending
    end

    test 'keeps the views of a failed write for the next flush' do
      fiction = fictions(:one)
      before = fiction.views.to_i
      @counter.add(fiction)

      Fiction.stub(:with_connection, ->(*) { raise ActiveRecord::ConnectionNotEstablished }) { @counter.flush }

      assert_equal({ 'Fiction' => { fiction.id => 1 } }, @counter.pending)
      @counter.flush

      assert_equal before + 1, fiction.reload.views
    end

    test 'stop writes what is left and ends the thread' do
      counter = ViewCounter.new(background: true, flush_every: 3600)
      fiction = fictions(:one)
      before = fiction.views.to_i
      counter.add(fiction)
      thread = counter.instance_variable_get(:@thread)

      counter.stop

      assert_not thread.alive?
      assert_equal before + 1, fiction.reload.views
    end
  end
end
