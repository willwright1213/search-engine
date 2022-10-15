class Index < ApplicationRecord
  belongs_to :word
  belongs_to :page
  validates :word_id, uniqueness: {scope: :page_id}
end
