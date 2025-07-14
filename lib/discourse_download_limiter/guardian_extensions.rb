module DiscourseDownloadLimiter
  module GuardianExtensions
    # 'upload' 객체를 인자로 받아 다운로드 가능 여부를 확인하는 새로운 메서드
    def can_download_upload?(upload)
      # 1. 관리자는 항상 허용
      return true if is_admin?

      # 2. 로그인한 사용자이고, 자신이 올린 파일인 경우 허용
      return true if user && user.id == upload.user_id

      # 3. 관리자 설정에서 허용된 그룹 ID 목록을 가져옴 (e.g., "1|3|5")
      allowed_group_ids_string = SiteSetting.download_allowed_group
      
      # 설정된 그룹이 없으면, 다운로드를 허용하지 않음 (엄격한 정책)
      return false if allowed_group_ids_string.blank?

      # 4. 그룹 ID 문자열을 실제 ID 배열로 변환
      allowed_group_ids = allowed_group_ids_string.split('|').map(&:to_i)

      # 5. 사용자가 로그인했고, 허용된 그룹 중 하나 이상의 멤버인지 확인
      user && user.groups.where(id: allowed_group_ids).exists?
    end
  end
end