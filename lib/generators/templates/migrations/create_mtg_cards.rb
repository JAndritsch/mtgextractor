class CreateMtgCards < ActiveRecord::Migration
  def self.up
    create_table :mtg_cards do |t|
      t.string     :name
      t.references :mtg_set
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_cards 
  end
end
