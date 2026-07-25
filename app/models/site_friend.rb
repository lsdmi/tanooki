# frozen_string_literal: true

SiteFriend = Data.define(:name, :url, :description, :section)

# Partner sites and communities linked from the /friends page.
class SiteFriend
  Section = Data.define(:id, :title, :tagline)

  SECTIONS = [
    Section.new(
      id: :watch,
      title: 'Перегляд',
      tagline: 'Платформи для перегляду аніме онлайн'
    ),
    Section.new(
      id: :manga,
      title: 'Манґа',
      tagline: 'Переклади українською'
    ),
    Section.new(
      id: :anime_voice,
      title: 'Аніме',
      tagline: 'Озвучення українською'
    ),
    Section.new(
      id: :support,
      title: 'Підтримка',
      tagline: 'ЗСУ та захисники України'
    )
  ].freeze

  LIST = [
    new(
      name: 'Mikai',
      url: 'https://mikai.me',
      description: 'Український аніме-проєкт для перегляду онлайн.',
      section: :watch
    ),
    new(
      name: 'PPMUA',
      url: 'https://t.me/PPMUa',
      description: 'Команда перекладів манґи українською.',
      section: :manga
    ),
    new(
      name: 'Animriya Team',
      url: 'https://t.me/animriya_team',
      description: 'Озвучення та локалізація аніме.',
      section: :anime_voice
    ),
    new(
      name: 'Повернись живим',
      url: 'https://savelife.in.ua/donate/',
      description: 'Благодійний фонд для армії та медицини.',
      section: :support
    )
  ].freeze

  def self.all
    LIST
  end

  def self.sections
    SECTIONS.filter_map do |section|
      friends = LIST.select { |friend| friend.section == section.id }
      next if friends.empty?

      { section:, friends: }
    end
  end
end
