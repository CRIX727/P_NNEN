# NNEN Architecture - Phase 1

## Goal

Build a single product with two user experiences:

- Nutricionista
- Paciente

The app must work offline first and synchronize with a backend when internet is available.

## Technical Stack

### Frontend

- Flutter
- Dart
- Riverpod
- go_router
- Dio
- Drift + SQLite
- flutter_secure_storage
- fl_chart
- file_picker
- image_picker

### Backend

- Node.js
- TypeScript
- NestJS
- Prisma
- PostgreSQL
- JWT
- refresh tokens
- bcrypt
- Socket.IO

## Architecture Style

- Clean Architecture
- separation by layers
- modular by domain
- local database as offline source of truth
- remote API as synchronization target

## Main Domains

- auth
- usuarios
- pacientes
- evaluaciones
- planes
- citas
- mensajes
- pagos
- documentos
- clinicas

## Folder Plan

### Frontend

```text
frontend/lib/
  core/
    constants/
    router/
    theme/
    services/
  data/
    local/
    remote/
    repository/
    sync/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    auth/
    nutricionista/
    paciente/
    shared/
```

### Backend

```text
backend/src/
  config/
  common/
  modules/
    auth/
    usuarios/
    pacientes/
    evaluaciones/
    planes/
    citas/
    mensajes/
    pagos/
    documentos/
    clinicas/
```

## Offline-First Strategy

1. Read from local SQLite first.
2. Write locally immediately.
3. Queue synchronization operations.
4. Sync when connectivity returns.
5. Resolve conflicts with last update wins.

## Phase Order

1. Foundation
2. Authentication and session
3. Nutricionista panel
4. Paciente panel
5. Offline sync
6. Chat and notifications
7. Production hardening

