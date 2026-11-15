import { useTranslation } from 'react-i18next';
import { QRCodeSVG } from 'qrcode.react';
import Sheet from './Sheet';

// Where the app is published (store page, APK or marketing site). Defaults to the Android APK install page.
const APP_DOWNLOAD_URL =
  import.meta.env.VITE_APP_DOWNLOAD_URL?.trim() || 'https://andrii-chaika.vercel.app/spotcheck/';

// Spots are created in the mobile app, which has the camera and the GPS the check needs.
export default function AddSpotNotice({ open, onClose }) {
  const { t } = useTranslation();
  const footer = (
    <a className="btn-primary btn-grow" href={APP_DOWNLOAD_URL} target="_blank" rel="noopener noreferrer">
      <span className="btn-label">{t('addSpot.mobileOnly.get')}</span>
    </a>
  );
  return (
    <Sheet open={open} onClose={onClose} title={t('addSpot.mobileOnly.title')} footer={footer}>
      <p className="detail-desc">{t('addSpot.mobileOnly.body')}</p>
      {/* Desde el ordenador se escanea con el móvil; en el propio móvil basta el botón */}
      <figure className="app-qr">
        <QRCodeSVG value={APP_DOWNLOAD_URL} size={168} marginSize={2} bgColor="#ffffff" fgColor="#000000" />
        <figcaption>{t('addSpot.mobileOnly.scan')}</figcaption>
      </figure>
    </Sheet>
  );
}
