class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.bigint :user_id
      t.string :title
      t.timestamps
    end
  end
end
