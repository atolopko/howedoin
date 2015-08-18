require 'spec_helper'

module Service
  describe Autofill do

    describe "#from_last_payee_txn" do
      let(:payee) { FactoryGirl.create(:payee, name: 'payee') }
      let!(:t1) { FactoryGirl.create(:txn, 
                                     payee: payee,
                                     date: Date.yesterday ) }

      it "creates new txn with same payee" do
        t2 = Autofill.from_last_payee_txn('payee', Date.today)
        expect(t2.payee.name).to eq 'payee'
      end

      it "creates new txn with specified date" do
        new_date = Date.today
        t2 = Autofill.from_last_payee_txn('payee', new_date)
        expect(t2.date).to eq new_date
      end

      it "creates new txn from most recent txn of matched payee" do
        t0 = FactoryGirl.create(:txn, date: Date.today - 2.days )
        t1.entries.each { |e| e.update_attributes(memo: 'this one') }
        t2 = Autofill.from_last_payee_txn('payee', Date.today)
        expect(t2.entries.first.memo).to eq 'this one'
      end

      it "creates new txn using Txn#dup" do
        t2 = t1.dup
        expect_any_instance_of(Txn).to receive(:dup).once.and_return(t2)
        expect(Autofill.from_last_payee_txn('payee', Date.today)).to eq t2
      end

      it "matches payee name ignoring case" do
        t2 = Autofill.from_last_payee_txn('PaYeE', Date.today)
        expect(t2.payee.name).to eq 'payee'
      end

      it "does not create new txn if payee name is ambiguous" do
        FactoryGirl.create(:payee, name: 'payee2')
        expect { Autofill.from_last_payee_txn('payee%', Date.today) }.to raise_error /ambigous payee name/
      end

      it "does not create new txn if matching payee name is not found " do
        expect { Autofill.from_last_payee_txn('x', Date.today) }.to raise_error /payee not found for name x/
      end

      it "ignores voided txn"
    end

  end
end
