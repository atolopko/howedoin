class User < ActiveRecord::Base
  self.table_name = 'fuser'

  attr_accessible :payment_default

  def self.payment_default
    User.where(payment_default: true).first
  end

  def set_payment_default
    transaction do
      User.payment_default.try { |u| u.update_attributes!(payment_default: false) }
      update_attributes!(payment_default: true)
    end
  end

end
