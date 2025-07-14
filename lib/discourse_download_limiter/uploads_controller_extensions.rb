module DiscourseDownloadLimiter
  module UploadsControllerExtensions
    # Discourse의 기존 'show' 액션이 실행되기 전에 이 코드를 먼저 실행
    def show
      # @upload 변수는 Discourse가 내부적으로 찾아놓은 상태
      # 우리가 만든 Guardian 메서드로 권한 확인
      # 'ensure_can...' 메서드는 권한이 없으면 자동으로 접근 거부(NotPermitted) 오류를 발생시킴
      guardian.ensure_can_download_upload!(@upload)

      # 권한 확인을 통과한 경우, 원래의 'show' 액션을 실행하여 파일 전송
      super
    end
  end
end