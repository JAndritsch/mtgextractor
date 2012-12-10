class MtgSet < ActiveRecord::Base
  require 'mtg_helpers'
  include MtgHelpers

  has_many :mtg_cards
  validates :name, :uniqueness => true, :presence => true

  alias_method :cards, :mtg_cards

  def folder_name
    slugify(name)
  end

  def common_icon
    "/assets/#{folder_name}/common_icon.jpg"
  end

  def uncommon_icon
    "/assets/#{folder_name}/uncommon_icon.jpg"
  end

  def rare_icon
    "/assets/#{folder_name}/rare_icon.jpg"
  end

  def mythic_icon
    "/assets/#{folder_name}/mythic-rare_icon.jpg"
  end

  def special_icon
    "/assets/#{folder_name}/special_icon.jpg"
  end

  def promo_icon
    "/assets/#{folder_name}/promo_icon.jpg"
  end

  def land_icon
    "/assets/#{folder_name}/basic-land_icon.jpg"
  end

end

