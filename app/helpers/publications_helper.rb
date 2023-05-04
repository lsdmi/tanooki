# frozen_string_literal: true

module PublicationsHelper
  def static_variables
    {
      new_publication_path: new_admin_tale_path,
      publication_edit_header: 'Оновити Звістку',
      publication_index_header: 'Керування Звістками',
      publication_new_header: 'Створити Звістку'
    }
  end

  def dynamic_variables(slug)
    {
      edit_publication_path: edit_admin_tale_path(slug),
      show_publication_path: tale_path(slug)
    }
  end
end
