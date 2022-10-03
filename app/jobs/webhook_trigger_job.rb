require 'uri'
require 'net/http'

class WebhookTriggerJob < ApplicationJob
  def perform(ticket_id)
    ticket = Ticket.find ticket_id
    uri = URI(ticket.webhook_url)
    res = Net::HTTP.get_response(uri)
    # some more process from webhook response
    # ...
  end
end
