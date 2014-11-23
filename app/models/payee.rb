class Payee < ActiveRecord::Base
  self.table_name = 'payee'

  # attr_accessible :name

  has_many :txns

  before_save :set_entered

  private

  def set_entered
    self.entered = Time.now
  end

end
