class BicyclesController < ApplicationController
  before_action :set_bicycle, only: %i[show edit update destroy]

  def index
    @bicycles = Bicycle.all
  end

  def show
  end

  def new
    @bicycle = Bicycle.new
  end

  def create
    @bicycle = Bicycle.new(bicycle_params)

    if @bicycle.save
      redirect_to @bicycle, notice: "Bicycle was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bicycle.update(bicycle_params)
      redirect_to @bicycle, notice: "Bicycle was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bicycle.destroy
    redirect_to bicycles_url, notice: "Bicycle was successfully destroyed."
  end

  private

  def set_bicycle
    @bicycle = Bicycle.find(params[:id])
  end

  def bicycle_params
    params.require(:bicycle).permit(:brand, :model, :usage_type, :color, :wheels)
  end
end
