const localDefaults = {
  clientEmail: 'cliente.flutter.test@englishreader.local',
  clientPassword: 'Cliente123*',
  adminEmail: 'admin@englishreader.local',
  adminPassword: 'Admin123*'
};

export const apiBaseUrl = process.env.API_BASE_URL?.trim() || 'http://localhost:3000/api/v1';

/// Devuelve credenciales E2E sin permitir defaults fuera del entorno local.
export function e2eCredentials({ includeAdmin = false } = {}) {
  const credentials = {
    clientEmail: readCredential('E2E_CLIENT_EMAIL', localDefaults.clientEmail),
    clientPassword: readCredential('E2E_CLIENT_PASSWORD', localDefaults.clientPassword)
  };

  if (!includeAdmin) return credentials;

  return {
    ...credentials,
    adminEmail: readCredential('E2E_ADMIN_EMAIL', localDefaults.adminEmail),
    adminPassword: readCredential('E2E_ADMIN_PASSWORD', localDefaults.adminPassword)
  };
}

/// Reconoce APIs locales donde los usuarios semilla no son credenciales reales.
export function isLocalApiUrl(rawUrl = apiBaseUrl) {
  try {
    const hostname = new URL(rawUrl).hostname.toLowerCase();
    return ['localhost', '127.0.0.1', '10.0.2.2', '::1', '[::1]'].includes(hostname);
  } catch {
    return false;
  }
}

function readCredential(name, localDefault) {
  const value = process.env[name]?.trim();
  if (value) return value;
  if (canUseLocalDefaults()) return localDefault;

  throw new Error(
    `Falta ${name}. Define credenciales E2E por variables de entorno cuando ` +
      'API_BASE_URL no es local o CI=true; los defaults solo sirven para la API local.'
  );
}

function canUseLocalDefaults() {
  return isLocalApiUrl() && !isCi();
}

function isCi() {
  const value = process.env.CI?.trim().toLowerCase();
  return value !== undefined && !['', '0', 'false', 'no'].includes(value);
}
