class TicketsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @tickets = Ticket.all
  end

  def create
    @ticket = Ticket.new ticket_params
    respond_to do |format|
      if @ticket.save
        WebhookTriggerJob.perform_later(@ticket.id)
        format.html do
          redirect_to root_path, notice: 'The Ticket has been created.'
        end

        format.json do
          render json: {
            user_id: @ticket.user_id, title: @ticket.title,
            webhook_url: @ticket.webhook_url
          }, status: 200
        end
      else
        format.html do
          flash.now[:alert] = full_error_messages
          render :new
        end

        format.json do
          render json: { errors: @ticket.errors }, status: 422
        end
      end
    end
  end

  def new
    @ticket = Ticket.new
  end

  private

  def ticket_params
    params.require(:ticket).permit(:payload)
  end

  def full_error_messages
    @ticket.errors.full_messages.join ', '
  end
end
