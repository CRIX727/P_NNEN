# NNEN: guia de produccion

Esta guia cubre el backend NestJS, la app Flutter para Android/Windows y la version Web.

## 1. Reglas de seguridad

- No subas `backend/.env`, `google-services.json`, cuentas de servicio, `key.properties` ni archivos `.jks`.
- Usa secretos diferentes para desarrollo y produccion.
- Cambia `JWT_ACCESS_SECRET` y `JWT_REFRESH_SECRET` por valores aleatorios largos.
- Usa PostgreSQL con TLS (`sslmode=require`) en la nube.
- En `FRONTEND_ORIGIN` coloca solo los dominios reales, separados por comas.
- El directorio `backend/uploads` debe usar almacenamiento persistente o un servicio de objetos antes de escalar a varias instancias.

## 2. Backend local

```powershell
cd "C:\Users\Cristofer\OneDrive\Escritorio\Proyecto NNEN\backend"
copy .env.example .env
npm ci
npx prisma generate
npx prisma db push
npm run build
npm test -- --runInBand
npm run start:prod
```

Comprobacion: abrir `http://localhost:3000/api/health`. Debe responder con `status: ok` y `database: ok`.

## 3. Backend con Docker

```powershell
cd "C:\Users\Cristofer\OneDrive\Escritorio\Proyecto NNEN\backend"
copy .env.docker.example .env
# Edita .env y cambia la contrasena y los secretos JWT.
$env:POSTGRES_PASSWORD = "una-contrasena-local-segura"
docker compose up --build -d
docker compose logs -f api
```

Para detenerlo sin borrar datos:

```powershell
docker compose down
```

Para borrar tambien la base local de Docker, solo si es intencional:

```powershell
docker compose down -v
```

## 4. Flutter: Web

Para desarrollo con backend local:

```powershell
cd "C:\Users\Cristofer\OneDrive\Escritorio\Proyecto NNEN\frontend"
flutter pub get
flutter run -d chrome --dart-define=NNEN_API_BASE_URL=http://localhost:3000/api
```

Build de produccion:

```powershell
flutter build web --release --dart-define=NNEN_API_BASE_URL=https://api.tu-dominio.com/api
```

Publica el contenido de `build/web` en un hosting estatico. El servidor debe redirigir las rutas desconocidas a `index.html` para que `go_router` funcione.

## 5. Flutter: Windows

```powershell
cd "C:\Users\Cristofer\OneDrive\Escritorio\Proyecto NNEN\frontend"
flutter run -d windows --dart-define=NNEN_API_BASE_URL=http://localhost:3000/api
flutter build windows --release --dart-define=NNEN_API_BASE_URL=https://api.tu-dominio.com/api
```

El ejecutable queda dentro de `build/windows/x64/runner/Release`.

## 6. Flutter: Android

Desarrollo con emulador:

```powershell
cd "C:\Users\Cristofer\OneDrive\Escritorio\Proyecto NNEN\frontend"
flutter run -d emulator-5554 --dart-define=NNEN_API_BASE_URL=http://10.0.2.2:3000/api
```

Para una red local real sustituye `10.0.2.2` por la IP de la computadora que ejecuta el backend. Para produccion usa HTTPS:

```powershell
flutter build appbundle --release --dart-define=NNEN_API_BASE_URL=https://api.tu-dominio.com/api
```

El AAB queda en `build/app/outputs/bundle/release/app-release.aab`.

### Firma Android

Genera una clave fuera del repositorio y crea `frontend/android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=nnen
storeFile=C:/ruta/segura/nnen-upload-key.jks
```

El proyecto usa la firma release si `key.properties` existe. Si no existe, usa la firma debug solo para permitir builds locales; ese APK no debe publicarse en Google Play.

## 7. Variables del backend

| Variable | Uso |
|---|---|
| `NODE_ENV` | `development` o `production`. |
| `PORT` | Puerto HTTP del backend. |
| `DATABASE_URL` | Conexion PostgreSQL. |
| `JWT_ACCESS_SECRET` | Firma de tokens de acceso. |
| `JWT_REFRESH_SECRET` | Firma de refresh tokens. |
| `JWT_ACCESS_EXPIRES_IN` | Duracion del access token. |
| `JWT_REFRESH_EXPIRES_IN` | Duracion del refresh token. |
| `FRONTEND_ORIGIN` | Dominios permitidos por CORS. |
| `FIREBASE_PROJECT_ID` | Proyecto de Firebase para push. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta al service account del backend. |

## 8. Checklist antes de publicar

- [ ] PostgreSQL administrado con backups y TLS.
- [ ] Backend desplegado con HTTPS.
- [ ] `/api/health` monitorizado.
- [ ] Secretos configurados en el proveedor, nunca en Git.
- [ ] CORS limitado a dominios reales.
- [ ] Migraciones Prisma versionadas y ejecutadas en el despliegue.
- [ ] Volumen persistente o almacenamiento externo para documentos.
- [ ] FCM probado en un dispositivo Android real.
- [ ] Web probada en Chrome y Edge.
- [ ] Windows probado en un equipo limpio.
- [ ] AAB firmado con clave release y probado antes de subirlo.
- [ ] Pruebas backend y `flutter analyze` en CI.
- [ ] Política de privacidad, términos y consentimiento clínico publicados.
- [ ] Logs y alertas configurados sin registrar contraseñas, JWT ni datos clínicos innecesarios.

## 9. Estado conocido de esta fase

La configuración de desarrollo, compilación, pruebas, Docker, health check, CORS, headers de seguridad y rate limiting queda preparada. La publicación real todavía requiere cuentas del proveedor, dominio, PostgreSQL cloud, clave de firma Android y validación de FCM en un dispositivo real.
