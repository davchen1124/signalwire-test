require 'test_helper'

describe TicketsController do
  let(:ticket) { tickets :one}
  let(:ticket_params) {
    {
      payload: '{ "user_id" : 1234, "title" : "My title", "tags" : ["tag1", "tag2", "TAG1"] }'
    }
  }

  describe 'Tickets listings' do
    it 'show all tickets' do
      get '/tickets'
      assert_select '.table__body .table__row', count: 2
    end

    it 'show welcome if there is no ticket' do
      Ticket.destroy_all
      get '/tickets'
      assert_select 'div', /Create your first ticket/
    end
  end

  describe 'new ticket' do
    it 'new ticket page' do
      get "/tickets/new"
      assert_select '#ticket_payload'
    end
  end

  describe 'create ticket' do
    describe 'validation' do
      describe 'should not create if user_id is empty' do
        let(:payload) { '{ "title" : "My title", "tags" : ["tag1", "tag2"] }' }

        it 'text/html request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { ticket: { payload: payload } }
          end
          assert_select '.alert', /User can't be blank/
        end

        it 'application/json request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { format: :json, ticket: { payload: payload } }
            assert_equal 422, response.status
            assert_equal "can't be blank",
              JSON.parse(response.body)['errors']['user_id'][0]
          end
        end
      end

      describe 'should not create if title is empty' do
        let(:payload) { '{ "user_id" : 1234, "title" : "", "tags" : ["tag1", "tag2"] }' }

        it 'text/html request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { ticket: { payload: payload } }
          end
          assert_select '.alert', /Title can't be blank/
        end

        it 'application/json request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { format: :json, ticket: { payload: payload } }
            assert_equal 422, response.status
            assert_equal "can't be blank",
              JSON.parse(response.body)['errors']['title'][0]
          end
        end
      end

      describe 'should not create if tags has equal or more 5' do
        let(:payload) { '{ "user_id" : 1234, "title" : "My title", "tags" : ["tag1", "tag2", "tag3", "tag4", "tag5"] }' }

        it 'text/html request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { ticket: { payload: payload } }
          end
          assert_select '.alert', /Tags should fewer than 5/
        end

        it 'application/json request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { format: :json, ticket: { payload: payload } }
            assert_equal 422, response.status
            assert_equal 'should fewer than 5',
              JSON.parse(response.body)['errors']['tags'][0]
          end
        end
      end

      describe 'should not create if payload is invalid' do
        let(:payload) { 'invalid data' }

        it 'text/html request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { ticket: { payload: payload } }
          end
          assert_select '.alert', /Payload Invalid JSON type/
        end

        it 'application/json request type' do
          assert_no_difference 'Ticket.count' do
            post '/tickets',
              params: { format: :json, ticket: { payload: payload } }
            assert_equal 422, response.status
            assert_equal 'Invalid JSON type',
              JSON.parse(response.body)['errors']['payload'][0]
          end
        end
      end
    end

    describe 'create ticket' do
      describe 'create ticket with tag update' do
        it 'text/html request type' do
          assert_difference 'Ticket.count' do
            assert_no_difference 'Tag.count' do
              post '/tickets', params: { ticket: ticket_params }
            end
          end
          assert_redirected_to root_path
          follow_redirect!
          assert_select '.notice', /The Ticket has been created./
          new_ticket = Ticket.last
          assert_equal 1234, new_ticket.user_id
          assert_equal 'My title', new_ticket.title
          assert new_ticket.webhook_url.include?('tag_name=tag1')
          assert new_ticket.webhook_url.include?('tag_count=3')
        end

        it 'application/json request type' do
          assert_difference 'Ticket.count' do
            assert_no_difference 'Tag.count' do
              post '/tickets', params: { format: :json, ticket: ticket_params }
              new_ticket = Ticket.last
              assert_equal 200, response.status
              assert_equal 1234, JSON.parse(response.body)['user_id']
              assert_equal 'My title', JSON.parse(response.body)['title']
              assert JSON.parse(response.body)['webhook_url'].include?('tag_name=tag1')
              assert JSON.parse(response.body)['webhook_url'].include?('tag_count=3')
            end
          end
        end
      end

      describe 'create ticket with tag creation' do
        before do
          Tag.destroy_all
        end

        it 'text/html request type' do
          assert_difference 'Ticket.count' do
            assert_difference 'Tag.count', 2 do
              post '/tickets', params: { ticket: ticket_params }
            end
          end
          assert_redirected_to root_path
          follow_redirect!
          assert_select '.notice', /The Ticket has been created./
          new_ticket = Ticket.last
          assert_equal 1234, new_ticket.user_id
          assert_equal 'My title', new_ticket.title
          assert new_ticket.webhook_url.include?('tag_name=tag1')
          assert new_ticket.webhook_url.include?('tag_count=2')
        end

        it 'application/json request type' do
          assert_difference 'Ticket.count' do
            assert_difference 'Tag.count', 2 do
              post '/tickets', params: { format: :json, ticket: ticket_params }
              new_ticket = Ticket.last
              assert_equal 200, response.status
              assert_equal 1234, JSON.parse(response.body)['user_id']
              assert_equal 'My title', JSON.parse(response.body)['title']
              assert JSON.parse(response.body)['webhook_url'].include?('tag_name=tag1')
              assert JSON.parse(response.body)['webhook_url'].include?('tag_count=2')
            end
          end
        end
      end
    end
  end
end
