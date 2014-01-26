class Account < ActiveRecord::Base
  self.table_name = 'account'

  attr_accessible :acct_type, :name, :number, :description, :opened_on, :closed, :closed_on, :entered

  # validates :acct_type, :inclusion 

  before_save :set_entered

  private 

  def set_entered
    self.entered = Time.zone.now
  end

end
