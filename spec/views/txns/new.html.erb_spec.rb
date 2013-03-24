require 'spec_helper'

describe "txns/new" do
  before(:each) do
    assign(:txn, stub_model(Txn).as_new_record)
  end

  it "renders new txn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", txns_path, "post" do
    end
  end
end
