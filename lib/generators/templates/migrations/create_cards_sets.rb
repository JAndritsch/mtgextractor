class CreateCardsSets < ActiveRecord::Migration
  def self.up
    create_table :cards_sets do |t|
      t.references :set
      t.references :card
      t.timestamps
    end
  end

  def self.down
    drop_table :cards_sets
  end
end
