class MtgCard < ActiveRecord::Base
  has_many :mtg_types, :through => "mtg_cards_mtg_types"
  belongs_to :mtg_set

  validates :name, :presence => true
  validates :mtg_set_id,  :presence => true
end
