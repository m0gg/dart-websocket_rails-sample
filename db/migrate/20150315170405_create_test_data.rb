class CreateTestData < ActiveRecord::Migration
  def change
    create_table :test_data do |t|
      t.string :title
      t.string :body

      t.timestamps
    end
  end
end
