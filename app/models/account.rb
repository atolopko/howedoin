class Account < ActiveRecord::Base
  attr_accessible :name, :number, :description, :opened_on, :closed, :closed_on
end
