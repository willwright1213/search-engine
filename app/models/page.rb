class Page < ApplicationRecord
  belongs_to :host
  has_many :links
  validates :name, uniqueness: {scope: :host_id}
end
