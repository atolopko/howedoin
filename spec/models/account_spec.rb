require 'spec_helper'

describe Account do

  let!(:account) { FactoryGirl.create(:account) }

  describe ".payment_default" do

    it "returns nil if no row with payment_default flag set" do
      expect(Account.payment_default).to be_nil
    end

    it "returns the Account with payment_default flag set" do
      account.update_attributes!(payment_default: true)
      expect(Account.payment_default).to eq account
    end
  end

  describe ".set_payment_default" do
    it "sets new payment default when no previous payment default account is set" do
      account.set_payment_default
      expect(Account.payment_default).to eq account
    end

    it "changes payment default account when previous payment default account is set" do
      payment_default_account = FactoryGirl.create(:account, payment_default: true)
      expect { account.set_payment_default }.
        to change { Account.payment_default }.
        from(payment_default_account).to(account)
    end

    it "keeps existing payment default account when error occurs" do
      account.update_attributes!(acct_type: 'liability')
      payment_default_account = FactoryGirl.create(:account, payment_default: true)
      expect {
        account.set_payment_default rescue nil
      }.not_to change { Account.payment_default }.from(payment_default_account)
    end

  end
end
