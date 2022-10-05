class Link < ApplicationRecord
  belongs_to :path
  validates :name, uniqueness: {scope: :path_id}
end
