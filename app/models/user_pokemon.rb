# frozen_string_literal: true

class UserPokemon < ApplicationRecord
  belongs_to :user
  belongs_to :pokemon

  FAILURE_MESSSAGE = "У-упс, невдала спроба!".freeze
  SUCCESS_MESSSAGE = "Вітаємо, із поповненням у команді!".freeze
end