class Host < ApplicationRecord
  has_many :paths
  validates :name, uniqueness: true
end
