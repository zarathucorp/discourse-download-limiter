module DiscourseDownloadLimiter
  module GuardianExtensions
    # 'upload' 객체를 인자로 받아 다운로드 가능 여부를 확인하는 새로운 메서드
    def can_download_upload?(upload)
      # 1. 관리자는 항상 허용
      return true if is_admin?

      # 2. 로그인한 사용자이고, 자신이 올린 파일인 경우 허용
      return true if user && user.id == upload.user_id

      # 3. 관리자 설정에서 허용 그룹 ID를 가져옴
      allowed_group_id = SiteSetting.download_allowed_group
      
      # 설정된 그룹이 없으면, 기본적으로 모든 사람에게 허용 (정책에 따라 false로 변경 가능)
      return true if allowed_group_id.blank?

      # 4. 사용자가 로그인했고, 설정된 그룹의 멤버인지 확인
      user && user.groups.exists?(id: allowed_group_id)
    end
  end
end