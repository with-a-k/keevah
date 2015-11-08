class AddLoanRequestCountToCategories < ActiveRecord::Migration
  def up
    add_column :categories, :loan_requests_count, :integer, null: false, default: 0

    Category.all.each do |category|
      Category.reset_counters(category.id, :loan_requests)
    end
  end

  def down
    remove_column :categories, :loan_requests_count
  end
end
