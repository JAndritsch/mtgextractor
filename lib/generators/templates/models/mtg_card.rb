class MtgCard < ActiveRecord::Base
  has_many :mtg_card_types
  has_many :mtg_types, :through => :mtg_card_types
  belongs_to :mtg_set

  validates :name, :presence => true
  validates :mtg_set_id,  :presence => true

  alias_method :types, :mtg_types
  alias_method :set, :mtg_set

end
