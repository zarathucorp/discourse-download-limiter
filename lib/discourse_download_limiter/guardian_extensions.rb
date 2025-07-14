module DiscourseDownloadLimiter
  module GuardianExtensions
    # 'upload' 객체를 인자로 받아 다운로드 가능 여부를 확인하는 새로운 메서드
    def can_download_upload?(upload)
      # --- 다운로드 권한 확인 로그 ---
      Rails.logger.info "--------------------------------------------------"
      Rails.logger.info "[Download Limiter] Checking download permission..."
      Rails.logger.info "[Download Limiter]   - Requester: #{user&.username || 'Guest User'}"
      Rails.logger.info "[Download Limiter]   - Requester's Groups: #{user&.groups&.pluck(:id, :name)&.inspect || 'N/A'}"
      Rails.logger.info "[Download Limiter]   - Is Admin?: #{is_admin?}"
      Rails.logger.info "[Download Limiter]   - Upload ID: #{upload.id}"
      Rails.logger.info "[Download Limiter]   - Uploader ID: #{upload.user_id}"
      Rails.logger.info "[Download Limiter]   - Is Uploader?: #{user && user.id == upload.user_id}"
      
      # 1. 관리자는 항상 허용
      return true if is_admin?

      # 2. 로그인한 사용자이고, 자신이 올린 파일인 경우 허용
      return true if user && user.id == upload.user_id

      # 3. 관리자 설정에서 허용된 그룹 ID 목록을 가져옴
      allowed_group_ids_string = SiteSetting.download_allowed_group
      Rails.logger.info "[Download Limiter]   - Allowed Groups Setting: '#{allowed_group_ids_string}'"
      
      # 설정된 그룹이 없으면 다운로드 거부
      if allowed_group_ids_string.blank?
        Rails.logger.info "[Download Limiter] Result: DENIED (No groups configured)"
        Rails.logger.info "--------------------------------------------------"
        return false
      end

      # 4. 그룹 ID 문자열을 실제 ID 배열로 변환
      allowed_group_ids = allowed_group_ids_string.split('|').map(&:to_i)
      Rails.logger.info "[Download Limiter]   - Parsed Group IDs: #{allowed_group_ids.inspect}"

      # 5. 사용자가 허용된 그룹의 멤버인지 확인
      is_member = user && user.groups.where(id: allowed_group_ids).exists?
      Rails.logger.info "[Download Limiter] Result: #{is_member ? 'ALLOWED' : 'DENIED'} (Group membership check)"
      Rails.logger.info "--------------------------------------------------"
      
      is_member
    end
  end
end