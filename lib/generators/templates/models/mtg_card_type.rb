class MtgCardType < ActiveRecord::Base
  has_many :mtg_cards, :through => "mtg_cards_mtg_types"
  validates :name, :presence => true, :uniqueness => true
end
