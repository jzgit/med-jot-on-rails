class Jot < ActiveRecord::Base
  attr_accessible :content, :order, :location, :context

  validates :content, :presence => true
end
