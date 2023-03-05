# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  validates :name, presence: true, length: { minimum: 3, maximum: 20 }, format: { with: /\A[a-zA-Z0-9 ]+\z/ }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :blogs
  has_many :comments
  has_many :publications
end
