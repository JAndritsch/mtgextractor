class MtgCardType < ActiveRecord::Base
  belongs_to :mtg_type
  belongs_to :mtg_card
end
