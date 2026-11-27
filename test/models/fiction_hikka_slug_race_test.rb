# frozen_string_literal: true

require 'test_helper'

# Two saves can pass the uniqueness validation together; the unique index decides the loser.
class FictionHikkaSlugRaceTest < ActiveSupport::TestCase
  test 'losing the race for a slug at the unique index is a validation error, not an exception' do
    fictions(:one).update_column(:hikka_slug, 'taken-slug')
    fiction = fictions(:two)
    fiction.hikka_slug = 'taken-slug'

    assert_not fiction.save(validate: false)
    assert_includes fiction.errors[:hikka_slug],
                    I18n.t('activerecord.errors.models.fiction.attributes.hikka_slug.taken')
    assert_nil fiction.reload.hikka_slug
  end

  test 'a unique violation on another index still raises' do
    error = ActiveRecord::RecordNotUnique.new("Duplicate entry 'x' for key 'fictions.index_fictions_on_slug'")
    fiction = fictions(:two)

    assert_raises(ActiveRecord::RecordNotUnique) do
      fiction.stub(:create_or_update, ->(*) { raise error }) { fiction.save }
    end
  end
end
