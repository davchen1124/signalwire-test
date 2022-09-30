class Tag < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  before_validation do
    self.name = name&.downcase
  end
end
