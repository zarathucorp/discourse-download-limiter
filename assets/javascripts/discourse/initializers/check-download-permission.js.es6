import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "download-limiter-initializer",

  initialize(container) {
    // Check if the plugin is enabled on the client side
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.download_limiter_enabled) {
      return;
    }

    withPluginApi("0.8.7", (api) => {
      api.on("file-download", (event) => {
        const currentUser = api.getCurrentUser();
        const upload = event.upload;
        const topic = event.topic;

        if (!currentUser) {
          // Prevent download if not logged in and restrictions apply
          alert("Please log in to download files.");
          return false; // Stop the download
        }

        const allowedGroupId = siteSettings.download_limiter_allowed_group;
        const isUploader = currentUser.id === upload.user_id;
        const isAdmin = currentUser.admin;
        const isMember = currentUser.groups.some(
          (g) => g.id === allowedGroupId
        );

        // Allow download if admin, uploader, or member of the allowed group
        if (isAdmin || isUploader || isMember || !allowedGroupId) {
          return true; // Proceed with the download
        } else {
          alert("You do not have permission to download this file.");
          return false; // Stop the download
        }
      });
    });
  },
};
