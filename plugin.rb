# name: discourse-download-limiter
# about: Restricts file downloads to members of a specific group or the uploader.
# version: 0.1
# authors: Your Name
# url: https://github.com/your-repo

enabled_site_setting :download_limiter_enabled


after_initialize do
  require_relative 'lib/discourse-download-limiter/guardian_extension'
  UploadsController.class_eval do
    prepend_before_action :check_download_permission, only: [:show, :show_short]

    private

    def check_download_permission
      # --- 초정밀 디버깅 로그 시작 ---
      Rails.logger.info "--- [DDL DEBUG] Step 1: check_download_permission method entered."

      upload = nil
      if params[:id].present?
        Rails.logger.info "--- [DDL DEBUG] Step 2a: Found 'id' param. Looking up upload by ID: #{params[:id]}."
        upload = Upload.find_by(id: params[:id])
        Rails.logger.info "--- [DDL DEBUG] Step 3a: Finished lookup by ID."
      elsif params[:base62].present?
        Rails.logger.info "--- [DDL DEBUG] Step 2b: Found 'base62' param. Looking up upload by short URL: #{params[:base62]}."
        upload = Upload.find_by_short_url(params[:base62])
        Rails.logger.info "--- [DDL DEBUG] Step 3b: Finished lookup by short URL."
      end

      Rails.logger.info "--- [DDL DEBUG] Step 4: Upload object is #{upload.nil? ? 'NIL' : 'FOUND'}. Upload ID: #{upload&.id}"

      return if upload.nil?
      Rails.logger.info "--- [DDL DEBUG] Step 5: Upload object is not nil. Proceeding."

      return if guardian.is_admin?
      Rails.logger.info "--- [DDL DEBUG] Step 6: User is not an admin. Proceeding."

      # guardian_extension.rb 파일의 로직을 호출합니다.
      can_download = guardian.can_download_upload?(upload)
      Rails.logger.info "--- [DDL DEBUG] Step 7: can_download_upload? returned: #{can_download}."

      unless can_download
        Rails.logger.info "--- [DDL DEBUG] Step 8: User cannot download. Raising InvalidAccess error."
        raise Discourse::InvalidAccess.new("You do not have permission to download this file.")
      end
      
      Rails.logger.info "--- [DDL DEBUG] Step 9: Check finished. User is allowed to download."
    end
  end

  Guardian.class_eval { include DiscourseDownloadLimiter::GuardianExtension }
end