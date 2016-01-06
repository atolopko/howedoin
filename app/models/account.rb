class Account < ActiveRecord::Base
  include HasEntered

  self.table_name = 'account'

  attr_accessible :acct_type, :name, :number, :description, :opened_on, :closed, :closed_on, :payment_default, :stmt_amounts_negated

  has_many :statements, foreign_key: 'acct_id'

  # validates :acct_type, :inclusion 

  def self.payment_default
    Account.where(payment_default: true).first
  end

  def set_payment_default
    transaction do
      Account.payment_default.try { |a| a.update_attributes!(payment_default: false) }
      update_attributes!(payment_default: true)
    end
  end

  def asset?
    acct_type == 'asset'
  end

  def liability?
    acct_type == 'liability'
  end

  def asset_or_liability?
    asset? || liability?
  end

  def income?
    acct_type == 'income'
  end

  def expense?
    acct_type == 'expense'
  end

  def income_or_expense?
    income? || expense?
  end

  def stmt_amounts_negated?
    stmt_amounts_negated
  end
end
