class CreateMtgCardsMtgTypes < ActiveRecord::Migration
  def self.up
    create_table :mtg_cards_mtg_types do |t|
      t.references :mtg_cards
      t.references :mtg_types
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_cards_mtg_types
  end
end
