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
      upload = nil
      if params[:id].present?
        upload = Upload.find_by(id: params[:id])
      elsif params[:base62].present?
        # ✅ 이 부분이 최종 수정되었습니다.
        upload = Upload.find_by_short_url(params[:base62])
      end

      return if upload.nil?

      return if guardian.is_admin?

      unless guardian.can_download_upload?(upload)
        raise Discourse::InvalidAccess.new("You do not have permission to download this file.")
      end
    end
  end

  Guardian.class_eval { include DiscourseDownloadLimiter::GuardianExtension }
end