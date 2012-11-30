class MtgType < ActiveRecord::Base
  has_many :mtg_card_types
  has_many :mtg_cards, :through => :mtg_card_types
  validates :name, :presence => true, :uniqueness => true
end
