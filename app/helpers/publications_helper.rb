# frozen_string_literal: true

module PublicationsHelper
  def static_variables
    {
      new_publication_path:,
      publication_edit_header:,
      publication_index_header:,
      publication_new_header:
    }
  end

  def dynamic_variables(slug, publication_class = nil)
    {
      edit_publication_path: edit_publication_path(slug, publication_class),
      show_publication_path: show_publication_path(slug, publication_class)
    }
  end

  def status_variables(status)
    case status
    when 'created'
      { class: 'bg-indigo-100 border-indigo-500 text-indigo-900', heading: 'Модерується' }
    when 'approved'
      { class: 'bg-teal-100 border-teal-500 text-teal-900', heading: 'Опубліковано' }
    else
      { class: 'bg-red-100 border-red-500 text-red-900', heading: 'Відхилено' }
    end
  end

  def publication_index_header
    case controller_path
    when 'blogs'
      'Мій Блог'
    when 'admin/blogs'
      'Модерування Блогів'
    else
      'Керування Звістками'
    end
  end

  private

  def new_publication_path
    blog_controller? ? new_blog_path : new_admin_tale_path
  end

  def publication_edit_header
    blog_controller? ? 'Оновити Допис' : 'Оновити Звістку'
  end

  def publication_new_header
    blog_controller? ? 'Створити Допис' : 'Створити Звістку'
  end

  def edit_publication_path(slug, publication_class)
    blog_controller?(publication_class) ? edit_blog_path(slug) : edit_admin_tale_path(slug)
  end

  def show_publication_path(slug, publication_class)
    blog_controller?(publication_class) ? blog_path(slug) : tale_path(slug)
  end

  def blog_controller?(publication_class = nil)
    publication_class == Blog || controller_name.to_sym == :blogs
  end
end
