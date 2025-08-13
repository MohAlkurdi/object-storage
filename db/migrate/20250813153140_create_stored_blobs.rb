class CreateStoredBlobs < ActiveRecord::Migration[7.2]
  def change
    create_table :stored_blobs do |t|
      t.string :key
      t.integer :size
      t.string :backend

      t.timestamps
    end
  end
end
