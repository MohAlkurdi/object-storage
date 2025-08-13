class StoredBlob < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :size, presence: true
  validates :backend, presence: true
end
