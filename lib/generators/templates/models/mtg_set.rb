class MTGSet < ActiveRecord::Base
  has_many :mtg_cards
  validates :name, :uniqueness => true, :presence => true
end

