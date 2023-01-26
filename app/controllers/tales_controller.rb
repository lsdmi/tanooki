class TalesController < ApplicationController
  before_action :set_tale, only: [:show, :edit, :update, :destroy]

  def show
  end

  def new
    @tale = Tale.new
  end

  def create
    @tale = Tale.new(tale_params)

    if @tale.save
      redirect_to root_path, notice: "Tale was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tale.update(tale_params)
      redirect_to tale_path(@tale), notice: "Tale was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tale.destroy
    redirect_to root_path, notice: "Tale was successfully destroyed."
  end

  private

  def set_tale
    @tale = Tale.find(params[:id])
  end

  def tale_params
    params.require(:tale).permit(:title, :description)
  end
end