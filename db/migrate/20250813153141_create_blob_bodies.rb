class CreateBlobBodies < ActiveRecord::Migration[7.2]
  def change
    create_table :blob_bodies do |t|
      t.string :key
      t.binary :data

      t.timestamps
    end
  end
end
