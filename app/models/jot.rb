class Jot < ActiveRecord::Base
  attr_accessible :content, :order, :location

  validates :content, :presence => true
end
