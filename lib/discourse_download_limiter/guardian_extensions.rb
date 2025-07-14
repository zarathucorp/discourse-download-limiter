module DiscourseDownloadLimiter
  module GuardianExtensions
    def can_download_upload?(upload)
      # --- 로그 추가 시작 ---
      Rails.logger.info "--------------------------------------------------"
      Rails.logger.info "[Downloader] Checking download permission for upload_id: #{upload.id}"
      Rails.logger.info "[Downloader] Requester: #{user&.username || 'Anonymous'}"
      Rails.logger.info "[Downloader] Uploader: #{upload.user.username}"
      # --- 로그 추가 끝 ---

      # 1. 관리자는 항상 허용
      if is_admin?
        Rails.logger.info "[Downloader] Result: Granted (User is Admin)"
        return true
      end

      # 2. 로그인한 사용자이고, 자신이 올린 파일인 경우 허용
      if user && user.id == upload.user_id
        Rails.logger.info "[Downloader] Result: Granted (User is the uploader)"
        return true
      end

      # 3. 관리자 설정에서 허용 그룹 ID를 가져옴
      allowed_group_id = SiteSetting.download_allowed_group
      
      if allowed_group_id.blank?
        Rails.logger.info "[Downloader] Result: Granted (No group restriction is set)"
        return true
      end
      
      # 4. 사용자가 로그인했고, 설정된 그룹의 멤버인지 확인
      is_member = user && user.groups.exists?(id: allowed_group_id)
      if is_member
        Rails.logger.info "[Downloader] Result: Granted (User is in the allowed group)"
        return true
      else
        Rails.logger.info "[Downloader] Result: Denied (User is not in the allowed group)"
        return false
      end
    end
  end
end