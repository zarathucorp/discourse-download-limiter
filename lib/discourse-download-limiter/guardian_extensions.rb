module DiscourseDownloadLimiter
  module GuardianExtension
    def can_download_upload?(upload)
      # 1. Uploader can always download their own file
      return true if user && user.id == upload.user_id

      # 2. Get the list of allowed group IDs from the setting
      # The setting value is a string like "1|10|12"
      allowed_group_ids_str = SiteSetting.download_limiter_allowed_groups

      # If no group is set, allow everyone
      return true if allowed_group_ids_str.blank?

      # 3. Convert the string of IDs into an array of integers
      allowed_group_ids = allowed_group_ids_str.split('|').map(&:to_i)

      # 4. Check if the user is a member of ANY of the allowed groups
      # .pluck(:id) gets all group IDs for the current user
      # `&` is the array intersection operator. If there's any overlap, the result won't be empty.
      user && (user.group_ids & allowed_group_ids).any?
    end
  end
end