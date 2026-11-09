const production = (process.env.NODE_ENV ?? 'development') === 'production';

export function validateEnvironment(config: Record<string, unknown>) {
  const required = ['DATABASE_URL', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET'];
  const missing = required.filter((key) => !String(config[key] ?? '').trim());

  if (missing.length > 0) {
    throw new Error(`Faltan variables de entorno obligatorias: ${missing.join(', ')}`);
  }

  if (production) {
    const weakSecrets = ['change-me-access-secret', 'change-me-refresh-secret'];
    if (weakSecrets.includes(String(config.JWT_ACCESS_SECRET)) || weakSecrets.includes(String(config.JWT_REFRESH_SECRET))) {
      throw new Error('En producción debes cambiar los secretos JWT por valores aleatorios seguros.');
    }
  }

  return {
    ...config,
    PORT: Number(config.PORT ?? 3000),
    FRONTEND_ORIGIN: String(config.FRONTEND_ORIGIN ?? 'http://localhost:3000'),
  };
}
