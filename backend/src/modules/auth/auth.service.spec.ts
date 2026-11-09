import { BadRequestException, ConflictException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  const prisma = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
  } as any;
  const jwtService = {
    signAsync: jest.fn().mockResolvedValue('token'),
    verifyAsync: jest.fn(),
  } as any;
  const configService = { get: jest.fn() } as any;
  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AuthService(prisma, jwtService, configService);
  });

  it('rechaza el registro con campos obligatorios vacíos', async () => {
    await expect(service.register({ nombre: ' ', correo: ' ', password: '', rol: 'paciente' }))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('rechaza el registro con correo existente', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 1 });
    await expect(service.register({ nombre: 'Ana', correo: 'ANA@test.com', password: '1234', rol: 'paciente' }))
      .rejects.toBeInstanceOf(ConflictException);
  });

  it('rechaza login de usuario inexistente', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    await expect(service.login({ correo: 'noexiste@test.com', password: '1234' }))
      .rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rechaza login con contraseña incorrecta', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 1,
      nombre: 'Ana',
      correo: 'ana@test.com',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuu',
      rol: UserRole.PACIENTE,
    });
    await expect(service.login({ correo: 'ana@test.com', password: 'incorrecta' }))
      .rejects.toBeInstanceOf(UnauthorizedException);
  });
});
