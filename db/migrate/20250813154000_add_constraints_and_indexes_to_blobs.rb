class AddConstraintsAndIndexesToBlobs < ActiveRecord::Migration[7.2]
  def change
    change_column_null :stored_blobs, :key, false
    change_column_null :stored_blobs, :size, false
    change_column_null :stored_blobs, :backend, false
    add_index :stored_blobs, :key, unique: true

    change_column_null :blob_bodies, :key, false
    change_column_null :blob_bodies, :data, false
    add_index :blob_bodies, :key, unique: true
  end
end
