require 'spec_helper'

describe Account do

  describe ".payment_default" do
    let!(:account) { FactoryGirl.create(:account) }

    it "returns nil if no row with payment_default flag set" do
      expect(Account.payment_default).to be_nil
    end

    it "returns the Account with payment_default flag set" do
      account.update_attributes!(payment_default: true)
      expect(Account.payment_default).to eq account
    end
  end
end
