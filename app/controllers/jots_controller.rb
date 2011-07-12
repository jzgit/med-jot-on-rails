class JotsController < ApplicationController
  respond_to :html, :json

  def index
    respond_to do |format|
      format.html
      format.json { respond_with Jot.all }
    end
  end

  def show
    respond_with Jot.find(params[:id])
  end

  def create
    jot = Jot.new(params)
    if jot.save
      respond_with jot
    else
      render :json => jot.errors, :status => :unprocessable_entity
    end
  end

  def update
    jot = Jot.find(params[:id])

    if jot.update_attributes(params)
      respond_with jot
    else
      render :json => jot.errors, :status => :unprocessable_entity
    end
  end

  def destroy
    jot = Jot.find(params[:id])
    jot.destroy
    render :json => nil
  end
end

