# Checks the content type and size of an Active Storage attachment.
# Used as `validates_with ImageValidator, attribute: :image`.
class ImageValidator < ActiveModel::Validator
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SIZE = 5.megabytes

  def validate(record)
    attachment = record.public_send(attribute_name)
    return unless attachment.respond_to?(:attached?) && attachment.attached?

    blob = attachment.blob
    record.errors.add(attribute_name, :content_type) unless ALLOWED_CONTENT_TYPES.include?(blob.content_type)
    record.errors.add(attribute_name, :file_size) if blob.byte_size > MAX_SIZE
  end

  private
    def attribute_name
      options[:attribute] || :image
    end
end
