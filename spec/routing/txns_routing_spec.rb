require "spec_helper"

describe TxnsController do
  describe "routing" do

    it "routes to #index" do
      get("/txns").should route_to("txns#index", :format => :json)
    end

    it "routes to #new" do
      get("/txns/new").should route_to("txns#new", :format => :json)
    end

    it "routes to #show" do
      get("/txns/1").should route_to("txns#show", :id => "1", :format => :json)
    end

    it "routes to #edit" do
      get("/txns/1/edit").should route_to("txns#edit", :id => "1", :format => :json)
    end

    it "routes to #create" do
      post("/txns").should route_to("txns#create", :format => :json)
    end

    it "routes to #update" do
      put("/txns/1").should route_to("txns#update", :id => "1", :format => :json)
    end

    it "routes to #destroy" do
      delete("/txns/1").should route_to("txns#destroy", :id => "1", :format => :json)
    end

  end
end
