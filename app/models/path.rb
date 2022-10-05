class Path < ApplicationRecord
  has_many :links
  validates :name, uniqueness: {scope: :host_id}
end
