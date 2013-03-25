class TxnsController < ApplicationController
  # GET /txns
  # GET /txns.json
  def index
    @txns = Txn.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @txns }
    end
  end

  # GET /txns/1
  # GET /txns/1.json
  def show
    @txn = Txn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @txn }
    end
  end

  def autofill
    if params[:payee] && params[:date]
      new_txn = Service::Autofill.from_last_payee_txn(params[:payee], params[:date])
    end
    respond_to do |format|
      format.json { render json: new_txn.to_json(:include => :entries) }
    end
  end

  # GET /txns/new
  # GET /txns/new.json
  def new
    @txn = Txn.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @txn }
    end
  end

  # GET /txns/1/edit
  def edit
    @txn = Txn.find(params[:id])
  end

  # POST /txns
  # POST /txns.json
  def create
    @txn = Txn.new(params[:txn])

    respond_to do |format|
      if @txn.save
        format.html { redirect_to @txn, notice: 'Txn was successfully created.' }
        format.json { render json: @txn, status: :created, location: @txn }
      else
        format.html { render action: "new" }
        format.json { render json: @txn.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /txns/1
  # PUT /txns/1.json
  def update
    @txn = Txn.find(params[:id])

    respond_to do |format|
      if @txn.update_attributes(params[:txn])
        format.html { redirect_to @txn, notice: 'Txn was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @txn.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /txns/1
  # DELETE /txns/1.json
  def destroy
    @txn = Txn.find(params[:id])
    @txn.destroy

    respond_to do |format|
      format.html { redirect_to txns_url }
      format.json { head :no_content }
    end
  end
end
