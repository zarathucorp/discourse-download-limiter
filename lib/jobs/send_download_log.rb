module Jobs
  class SendDownloadLog < ::Jobs::Base
    def execute(args)
      post_url = args[:post_url]
      user_id = args[:user_id]
      upload_id = args[:upload_id]
      download_allowed = args[:download_allowed]

      return unless post_url.present? && upload_id.present?

      upload = Upload.find_by(id: upload_id)
      return unless upload

      user = user_id ? User.find_by(id: user_id) : nil

      payload = {
        user_id: user&.id,
        username: user&.username,
        upload_id: upload.id,
        original_filename: upload.original_filename,
        download_allowed: download_allowed,
        timestamp: Time.now.iso8601
      }

      uri = URI.parse(post_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      request.body = payload.to_json

      begin
        response = http.request(request)
        Rails.logger.info "Download log sent to #{post_url}. Response: #{response.code} #{response.message}"
      rescue => e
        Rails.logger.error "Failed to send download log to #{post_url}. Error: #{e.message}"
      end
    end
  end
end
