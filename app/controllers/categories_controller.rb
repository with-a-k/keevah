class CategoriesController < ApplicationController
  def index
    @categories = Category.all
  end

  def show
    @category = Category.find(params[:id])
    @loan_requests = @category.loan_requests.paginate(:page => params[:page], :total_entries => @category.loan_requests.count)
  end
end
