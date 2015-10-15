class CreateDocument < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.references :user
      t.string :image
      t.timestamps
    end
  end
end
