# frozen_string_literal: true

module PublicationsHelper
  def static_variables
    @static_variables ||= {
      new_publication_path: blog_controller ? new_blog_path : new_admin_tale_path,
      publication_edit_header: blog_controller ? 'Оновити Пост' : 'Оновити Звістку',
      publication_index_header: blog_controller ? 'Керування Блогами' : 'Керування Звістками',
      publication_new_header: blog_controller ? 'Створити Пост' : 'Створити Звістку'
    }
  end

  def dynamic_variables(slug, publication_class = nil)
    {
      edit_publication_path: blog_controller(publication_class) ? edit_blog_path(slug) : edit_admin_tale_path(slug),
      show_publication_path: blog_controller(publication_class) ? blog_path(slug) : tale_path(slug)
    }
  end

  def blog_controller(publication_class = nil)
    return true if publication_class == Blog

    controller_name.to_sym == :blogs
  end
end
