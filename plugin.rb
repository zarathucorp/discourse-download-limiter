# name: discourse-download-limiter
# about: Restricts file downloads to a specific group and the uploader.
# version: 1.0
# authors: Changwoo Lim
# url: https://github.com/ChangwooLim/discourse-download-limiter
after_initialize do
  # --- 서버 측(Ruby) 확장 코드 로드 ---
  
  # Guardian 클래스에 커스텀 권한 로직을 추가하기 위한 모듈 로드
  require_relative 'lib/discourse_download_limiter/guardian_extensions'
  
  # UploadsController를 수정하기 위한 모듈 로드
  require_relative 'lib/discourse_download_limiter/uploads_controller_extensions'

  # --- 로드된 코드를 Discourse에 적용 ---
  
  # Guardian 클래스에 우리가 만든 GuardianExtensions 모듈을 포함시켜
  # can_download_upload? 메서드를 사용할 수 있게 함
  Guardian.include(DiscourseDownloadLimiter::GuardianExtensions)

  # UploadsController 클래스를 열어, 우리가 만든 UploadsControllerExtensions 모듈의 코드를
  # 기존 코드보다 먼저 실행하도록 설정 (prepend)
  UploadsController.class_eval do
    prepend DiscourseDownloadLimiter::UploadsControllerExtensions
  end
end