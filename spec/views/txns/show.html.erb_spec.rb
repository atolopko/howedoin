require 'spec_helper'

describe "txns/show" do
  before(:each) do
    @txn = assign(:txn, stub_model(Txn))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
