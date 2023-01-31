class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, length: { minimum: 3, maximum: 10 }, format: { with:  /\A[a-zA-Z0-9 ]+\z/ }
end
