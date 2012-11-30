class CreateMtgCards < ActiveRecord::Migration
  def self.up
    create_table :mtg_cards do |t|
      t.string     :name
      t.string     :gatherer_url
      t.string     :multiverse_id
      t.string     :image_url
      t.string     :mana_cost
      t.string     :converted_cost
      t.string     :oracle_text
      t.string     :power
      t.string     :toughness
      t.string     :loyalty
      t.string     :rarity
      t.string     :transformed_id
      t.string     :colors
      t.references :mtg_set
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_cards 
  end

end
