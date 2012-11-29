class CreateCards < ActiveRecord::Migration
  def self.up
    create_table :cards do |t|
      t.string     :name
      t.references :set
      t.timestamps
    end
  end

  def self.down
    drop_table :cards 
  end
end
