class CreateTaggables < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name
      t.string :kind
      t.timestamps
    end

    create_table :taggings do |t|
      t.integer :tag_id
      t.references :taggable, :polymorphic => true
      t.references :owner, :polymorphic => true
      t.timestamps
    end
    
    add_index :tags, [:name, :kind]
    add_index :taggings, [:tag_id]  
    add_index :taggings, [:taggable_id, :taggable_type]
    add_index :taggings, [:owner_id, :owner_type]
  end
  
  def self.down
    drop_table :taggings
    drop_table :tags
  end
end