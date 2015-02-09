require 'spec_helper'

describe User do
  let!(:user) { FactoryGirl.create(:user) }

  describe ".payment_default" do
    it "returns nil if no row with payment_default flag set" do
      expect(User.payment_default).to be_nil
    end

    it "returns the User with payment_default flag set" do
      user.update_attributes!(payment_default: true)
      expect(User.payment_default).to eq user
    end
  end

  describe ".set_payment_default" do
    it "sets new payment default when no previous payment default user is set" do
      user.set_payment_default
      expect(User.payment_default).to eq user
    end

    it "changes payment default user when previous payment default user is set" do
      payment_default_user = FactoryGirl.create(:user, payment_default: true)
      expect { user.set_payment_default }.
        to change { User.payment_default }.
        from(payment_default_user).to(user)
    end

    it "keeps existing payment default user when error occurs" do
      payment_default_user = FactoryGirl.create(:user, payment_default: true)
      user.stub(:update_attributes!).and_raise "sorry"
      expect {
        user.set_payment_default rescue nil
      }.not_to change { User.payment_default }.from(payment_default_user)
    end
  end
end
