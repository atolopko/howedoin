require 'spec_helper'

describe TxnBuilder do
  let!(:u) { FactoryGirl.create(:user, fullname: 'me', nickname: 'me') }
  let!(:p) { FactoryGirl.create(:payee, name: 'market') }
  let!(:a1) { FactoryGirl.create(:account, :asset, name: 'bank') }
  let!(:a2) { FactoryGirl.create(:account, :expense, name: 'food') }

  def assert_matches(t)
    expect(t.payee).to eq p
    expect(t.date).to eq Date.new(2014, 11, 2)
    expect(t.entries.first.account).to eq a2
    expect(t.entries.first.amount.to_s).to eq '11.01'
    expect(t.entries.first.user).to eq u
    expect(t.entries.last.account).to eq a1
    expect(t.entries.last.amount.to_s).to eq '-11.01'
    expect(t.entries.last.user).to eq u
  end
  
  it "creates a Txn using string identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by('me').
      paying('market').
      using('bank').
      buying('food').
      costing('11.01').
      create
  end

  it "creates a Txn using string wildcard identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by('m%').
      paying('MARK%').
      using('b%k').
      buying('%ood').
      costing('11.01').
      create
  end

  it "creates Txn using primary key identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by(u.id).
      paying(p.id).
      using(a1.id).
      buying(a2.id).
      costing('11.01').
      create
  end

  it "creates Txn using object identifiers" do
    assert_matches TxnBuilder.new.
      on('2014-11-02').
      by(u).
      paying(p).
      using(a1).
      buying(a2).
      costing('11.01').
      create
  end

  it "sets num on balancing entry" do
    t = TxnBuilder.new.
      on('2014-11-02').
      by(u).
      using(a1).
      num(101).
      buying(a2).
      costing('1').
      create
    expect(t.reload.entries.last.num).to eq '101'
  end

  describe "missing values" do
    it "uses default payment account" do
      a1.update_attributes!(payment_default: true)
      assert_matches TxnBuilder.new.
        on('2014-11-02').
        by(u).
        paying(p).
        buying(a2).
        costing('11.01').
        create
    end

    it "uses current date" do
      Timecop.freeze do
        t = TxnBuilder.new.
          by(u).
          using(a1).
          paying(p).
          buying(a2).
          costing('1.00').
          create
        expect(t.date).to eq Date.today
      end
    end

    it "allows missing payee" do
      expect { 
        TxnBuilder.new.
        on('2014-11-02').
        by(u).
        using(a1).
        buying(a2).
        costing('11.01').
        create
      }.not_to raise_error
    end

    it "allows nil payee" do
      expect { 
        TxnBuilder.new.
        on('2014-11-02').
        by(u).
        paying(nil).
        using(a1).
        buying(a2).
        costing('11.01').
        create
      }.not_to raise_error
    end

    it "accepts optional memo with category" do
      t = TxnBuilder.new.
        on('2014-11-02').
        by(u).
        using(a1).
        buying(a2, 'memo').
        costing('1').
        create
      expect(t.entries.first.memo).to eq 'memo'
    end

    it "raises error on missing inputs" do
      expect { TxnBuilder.new.create }.
        to raise_error "Cannot create Txn, missing amount ('costing'), from account ('using'), to account ('buying')"
    end
  end

  describe "multi-entry" do
    let!(:u2) { FactoryGirl.create(:user, fullname: 'u2', nickname: 'u2') }
    let!(:a3) { FactoryGirl.create(:account, :expense, name: 'drink') }

    def assert_matches(t)
      expect(t.payee).to eq p
      expect(t.date).to eq Date.new(2014, 11, 2)
      expect(t.entries.first.account).to eq a2
      expect(t.entries.first.amount.to_s).to eq '11.01'
      expect(t.entries.first.user).to eq u
      expect(t.entries[1].account).to eq a3
      expect(t.entries[1].amount.to_s).to eq '12.02'
      expect(t.entries[1].user).to eq u
      expect(t.entries.last.account).to eq a1
      expect(t.entries.last.amount.to_s).to eq '-23.03'
      expect(t.entries.last.user).to eq u
    end
  
    it "creates additional entry after #also call" do
      assert_matches TxnBuilder.new.
        on('2014-11-02').
        by(u).
        paying(p).
        using(a1).
        buying(a2).
        costing('11.01').
        also.
        buying(a3).
        costing('12.02').
        create
    end

    it "reuses user from previous entry if unspecified on subequent entries" do
      t = TxnBuilder.new.
        on('2014-11-02').
        by(u).
        using(a1).
        buying(a2).
        costing('1').
        also.
        buying(a3).
        costing('1').
        create
      expect(t.entries[1].user).to eq u
    end

    it "changes user from previous entry if specified differently on subequent entries" do
      u2 = FactoryGirl.create(:user, fullname: 'you', nickname: 'you')
      t = TxnBuilder.new.
        on('2014-11-02').
        by(u).
        using(a1).
        buying(a2).
        costing('1').
        also.
        by(u2).
        buying(a3).
        costing('1').
        create
      expect(t.entries[1].user).to eq u2
    end
 end
end
