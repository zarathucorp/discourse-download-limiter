# name: discourse-download-limiter
# about: Restricts file downloads to members of a specific group or the uploader.
# version: 0.1
# authors: Your Name
# url: https://github.com/your-repo

enabled_site_setting :download_limiter_enabled

# Load the guardian extension
load File.expand_path('lib/discourse-download-limiter/guardian_extension.rb', __FILE__)

after_initialize do
  # Prepend our custom module to the UploadsController
  # This is the standard way to add logic before the original method runs
  UploadsController.class_eval do
    prepend_before_action :check_download_permission, only: [:show]

    private

    def check_download_permission
      return if guardian.is_admin? # Admins can always download

      # Get the requested upload
      upload = Upload.find_by(id: params[:id])
      return if upload.nil? # Should be handled by Discourse, but as a safeguard

      unless guardian.can_download_upload?(upload)
        # If the user doesn't have permission, deny access
        raise Discourse::InvalidAccess.new("You do not have permission to download this file.")
      end
    end
  end

  # Extend the Guardian with our custom logic
  # The Guardian is Discourse's central permission checking class
  Discourse::Application.routes.reload do
    # This ensures our Guardian changes are applied
    Guardian.class_eval { include DiscourseDownloadLimiter::GuardianExtension }
  end
end