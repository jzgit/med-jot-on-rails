class CreateJots < ActiveRecord::Migration
  def change
    create_table :jots do |t|
      t.string :content
      t.string :location
      t.string :context
      t.integer :order

      t.timestamps
    end
  end
end
