# name: discourse-download-limiter
# about: Restricts file downloads to members of a specific group or the uploader.
# version: 0.1
# authors: Your Name
# url: https://github.com/your-repo

enabled_site_setting :download_limiter_enabled

require_relative 'lib/discourse-download-limiter/guardian_extension'

after_initialize do
  UploadsController.class_eval do
    prepend_before_action :check_download_permission, only: [:show, :show_short]

    private

    def check_download_permission
      # ✅ 'show'와 'show_short' 경로에 따라 파일을 찾는 로직을 수정
      upload = nil
      if params[:id].present?
        upload = Upload.find_by(id: params[:id])
      elsif params[:base62].present?
        upload = Upload.find_by(short_url: params[:base62])
      end

      # Get the requested upload
      return if upload.nil? # Should be handled by Discourse, but as a safeguard

      return if guardian.is_admin? # Admins can always download

      unless guardian.can_download_upload?(upload)
        # If the user doesn't have permission, deny access
        raise Discourse::InvalidAccess.new("You do not have permission to download this file.")
      end
    end
  end

  Guardian.class_eval { include DiscourseDownloadLimiter::GuardianExtension }
end