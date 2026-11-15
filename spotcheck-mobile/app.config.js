// google-services.json is not in git (it holds the Firebase API key). Locally it is read from
// ./google-services.json; on EAS it comes from the GOOGLE_SERVICES_JSON file environment variable.
module.exports = ({ config }) => ({
  ...config,
  android: {
    ...config.android,
    googleServicesFile: process.env.GOOGLE_SERVICES_JSON ?? config.android.googleServicesFile,
  },
});
