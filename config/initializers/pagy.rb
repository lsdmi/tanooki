# frozen_string_literal: true

require 'pagy/extras/array'
require 'pagy/extras/countless'
require 'pagy/extras/i18n'
require 'pagy/extras/overflow'

Pagy::I18n.load(locale: 'uk')

Pagy::DEFAULT[:overflow] = :last_page
