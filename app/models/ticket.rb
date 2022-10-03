class Ticket < ApplicationRecord
  # default created_at will be used for datetime it was received

  attr_accessor :payload
  attr_accessor :tags

  validate :payload_validate
  validates :user_id, :title, presence: true
  validate :tags_validate

  before_create :store_tags
  before_create :generate_webhook_url

  WEBHOOK_ENDPOINT = 'https://signalwire.com/api/webhook'

  private

  def payload_validate
    return if payload.blank?
    data = JSON.parse(payload).with_indifferent_access
    self.user_id = data[:user_id]
    self.title = data[:title]
    self.tags = data[:tags]
  rescue
    errors.add 'payload', 'Invalid JSON type'
  end

  def tags_validate
    if tags.is_a?(Array) && tags.length >= 5
      errors.add 'tags', 'should fewer than 5'
    end
  end

  def store_tags
    # to_s method is needed if tags array has integer value
    items = tags.reject{|i| i.blank?}.map{|i| i.to_s.downcase}
      .group_by(&:itself).transform_values(&:count)
    items.each do |item|
      tag = Tag.find_by_name item[0]
      if tag
        tag.update count: tag.count.to_i + item[1]
      else
        Tag.create! name: item[0], count: item[1]
      end
    end
  end

  def generate_webhook_url
    # max_count = Tag.maximum(:count)
    # tags = Tag.where(count: max_count)
    # query_string = {tag_name: tags.pluck(:name), tag_count: tags.pluck(:count)}.to_query
    tag = Tag.order(:count).last
    query_string = {tag_name: tag&.name, tag_count: tag&.count}.to_query
    self.webhook_url = [WEBHOOK_ENDPOINT, CGI.unescape(query_string)].join '?'
  end
end
