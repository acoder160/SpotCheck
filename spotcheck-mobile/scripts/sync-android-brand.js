// Syncs app.json icon + splash screen assets into android/app/src/main/res
const path = require('path');
const fs = require('fs');
const projectRoot = path.join(__dirname, '..');
const { setIconAsync } = require(path.join(projectRoot, 'node_modules/@expo/prebuild-config/build/plugins/icons/withAndroidIcons'));
const { getAndroidSplashConfig } = require(path.join(projectRoot, 'node_modules/expo-splash-screen/plugin/build/getAndroidSplashConfig'));
const { setSplashImageDrawablesAsync } = require(path.join(projectRoot, 'node_modules/expo-splash-screen/plugin/build/withAndroidSplashImages'));

const appJson = JSON.parse(fs.readFileSync(path.join(projectRoot, 'app.json'), 'utf8')).expo;

async function main() {
  // Clear .expo/web/cache so @expo/image-utils regenerates fresh images
  const cacheDir = path.join(projectRoot, '.expo', 'web', 'cache');
  fs.rmSync(cacheDir, { recursive: true, force: true });

  console.log('Generating Android launcher & adaptive icons...');
  await setIconAsync(projectRoot, {
    icon: appJson.icon,
    foregroundImage: appJson.android.adaptiveIcon.foregroundImage,
    backgroundColor: appJson.android.adaptiveIcon.backgroundColor,
    backgroundImage: appJson.android.adaptiveIcon.backgroundImage,
    monochromeImage: appJson.android.adaptiveIcon.monochromeImage,
    isAdaptive: true,
  });

  const splashPlugin = appJson.plugins.find(
    (p) => Array.isArray(p) && p[0] === 'expo-splash-screen',
  );
  const splashConfig = getAndroidSplashConfig(splashPlugin[1]);

  console.log('Generating Android splash screen drawables...');
  await setSplashImageDrawablesAsync(splashConfig, projectRoot);

  console.log('Android icon and splash screen resources updated successfully.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
