class CreateQboClients < ActiveRecord::Migration
  def change
    create_table :qbo_clients do |t|
      t.references :user
      t.string :token
      t.string :secret
      t.integer :realm_id, unique: true
      t.datetime :token_expires_at
      t.datetime :reconnect_token_at
      t.timestamps
    end
    add_index :qbo_clients, :realm_id, :unique => true
  end
end
