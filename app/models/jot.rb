# class Jot < ActiveRecord::Base
#   attr_accessible :content, :order, :location, :context

#   validates :content, :presence => true
# end


class Jot
  include Mongoid::Document
  include Mongoid::Timestamps
  field :content
  field :order, type: Integer
  field :location
  field :context

  validates :content, :presence => true
end
