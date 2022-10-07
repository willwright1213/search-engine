class Link < ApplicationRecord
  belongs_to :page
  validates :link_to, uniqueness: {scope: :page_id}
end
