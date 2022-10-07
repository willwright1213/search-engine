class Host < ApplicationRecord
  has_many :pages
  validates :name, uniqueness: true
end
