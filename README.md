# NNEN

Plataforma multiplataforma de seguimiento nutricional para nutricionistas y pacientes.

## Componentes

- `frontend`: Flutter para Android, Windows y Web.
- `backend`: NestJS + Prisma + PostgreSQL.
- `docs/PRODUCCION.md`: comandos de desarrollo, builds y checklist de despliegue.

## Arranque rapido

1. Inicia PostgreSQL y configura `backend/.env`.
2. Ejecuta el backend con `npm run start:dev`.
3. Ejecuta Flutter con el destino deseado y `--dart-define=NNEN_API_BASE_URL=...`.

Consulta la guia de produccion antes de publicar cualquier build.

NNEN is a multiplatform nutrition platform for mobile and PC.

## Structure

- `frontend/`: Flutter app for mobile, desktop and web.
- `backend/`: NestJS API with PostgreSQL and Prisma.
- `docs/`: Architecture notes and phase planning.

## Phase 1

Foundation only:

- architecture definition
- folder structure
- base navigation
- theme setup
- core dependencies
- domain models
- offline-first strategy

