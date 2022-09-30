class AddWebhookUrlFieldToTickets < ActiveRecord::Migration[5.2]
  def change
    add_column :tickets, :webhook_url, :string
  end
end
