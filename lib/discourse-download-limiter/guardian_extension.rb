module DiscourseDownloadLimiter
  module GuardianExtension
    def can_download_upload?(upload)
      # --- 로그 시작 ---
      Rails.logger.info "--- [Download Limiter Check] ---"
      Rails.logger.info "File: #{upload.original_filename} (Upload ID: #{upload.id}), Uploader User ID: #{upload.user_id}"

      # 요청한 유저 정보 확인
      if user
        Rails.logger.info "Requester: #{user.username} (User ID: #{user.id})"
        Rails.logger.info "Requester's Group IDs: #{user.group_ids.inspect}"
      else
        Rails.logger.info "Requester: Not logged in."
      end
      # --- 로그 준비 완료 ---

      # 1. 업로더 본인인지 확인
      if user && user.id == upload.user_id
        Rails.logger.info "Decision: ALLOWED (User is the uploader)."
        Rails.logger.info "------------------------------------"
        return true
      end

      # 2. 설정에서 차단된 그룹 목록 가져오기
      denied_group_ids_str = SiteSetting.download_limiter_denied_groups
      Rails.logger.info "Denied Group IDs from Setting: #{denied_group_ids_str.inspect}"
      denied_group_ids = denied_group_ids_str.split('|').map(&:to_i)
      Rails.logger.info "Parsed Denied Group IDs: #{denied_group_ids.inspect}"
      # 3. 사용자가 차단된 그룹에 속해 있는지 확인
      if user && (user.group_ids & denied_group_ids).any?
        Rails.logger.info "Decision: DENIED (User is in a denied group)."
        Rails.logger.info "------------------------------------"
        return false
      end

      # 4. "Log and Allow" 그룹 확인
      allowed_with_log_group_ids_str = SiteSetting.download_limiter_allowed_with_log_groups
      api_route = SiteSetting.download_limiter_log_api_route
      Rails.logger.info "Allowed with Log Group IDs from Setting: #{allowed_with_log_group_ids_str.inspect}"

      if user && allowed_with_log_group_ids_str.present?
        allowed_with_log_group_ids = allowed_with_log_group_ids_str.split('|').map(&:to_i)
        if (user.group_ids & allowed_with_log_group_ids).any?
          if api_route.present?
            Jobs.enqueue(:log_download, user_id: user.id, upload_id: upload.id, timestamp: Time.now.iso8601)
            Rails.logger.info "Decision: ALLOWED (User in 'log and allow' group). Enqueued log job."
          else
            Rails.logger.info "Decision: ALLOWED (User in 'log and allow' group). API route not set, skipping log."
          end
          Rails.logger.info "------------------------------------"
          return true
        end
      end

      # 2. 설정에서 허용된 그룹 목록 가져오기
      allowed_group_ids_str = SiteSetting.download_limiter_allowed_groups
      Rails.logger.info "Allowed Group IDs from Setting: #{allowed_group_ids_str.inspect}"

      # 3. 설정된 그룹이 없으면 모두 허용
      if allowed_group_ids_str.blank?
        Rails.logger.info "Decision: ALLOWED (No group restriction is set)."
        Rails.logger.info "------------------------------------"
        return true
      end

      # 4. 사용자가 허용된 그룹에 속해 있는지 확인
      allowed_group_ids = allowed_group_ids_str.split('|').map(&:to_i)
      
      # 로그인을 안 했거나 그룹이 없으면 is_member는 false가 됨
      is_member = user && (user.group_ids & allowed_group_ids).any?

      if is_member
        Rails.logger.info "Decision: ALLOWED (User is in an allowed group)."
        Rails.logger.info "------------------------------------"
        return true
      else
        Rails.logger.info "Decision: DENIED (User is not uploader and not in an allowed group)."
        Rails.logger.info "------------------------------------"
        return false
      end
    end
  end
end