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
    prefix = using_asset_pipeline? ? asset_pipeline_prefix : "/images"
    "#{prefix}/#{folder_name}/common_icon.jpg"
  end

  def uncommon_icon
    "#{prefix}/#{folder_name}/uncommon_icon.jpg"
  end

  def rare_icon
    "#{prefix}/#{folder_name}/rare_icon.jpg"
  end

  def mythic_icon
    "#{prefix}/#{folder_name}/mythic-rare_icon.jpg"
  end

  def special_icon
    "#{prefix}/#{folder_name}/special_icon.jpg"
  end

  def promo_icon
    "#{prefix}/#{folder_name}/promo_icon.jpg"
  end

  def land_icon
    "#{prefix}/#{folder_name}/basic-land_icon.jpg"
  end

end

