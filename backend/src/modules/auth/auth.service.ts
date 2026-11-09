import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AppointmentStatus, PaymentStatus, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';

import { PrismaService } from '../../common/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';

const SALT_ROUNDS = 10;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const LOGIN_BLOCK_MS = 15 * 60 * 1000;
const MAX_LOGIN_FAILURES = 5;

interface LoginContext {
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponseDto> {
    const correo = dto.correo.trim().toLowerCase();
    const nombre = dto.nombre.trim();

    if (!nombre || !correo || !dto.password) {
      throw new BadRequestException('Completa todos los campos');
    }

    const exists = await this.prisma.user.findUnique({ where: { correo } });
    if (exists) {
      throw new ConflictException('El correo ya está registrado');
    }

    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);
    const user = await this.prisma.user.create({
      data: {
        nombre,
        correo,
        passwordHash,
        rol: this.toPrismaRole(dto.rol),
      },
    });

    if (user.rol === UserRole.PACIENTE) {
      const existingPatient = await this.prisma.patient.findFirst({
        where: { correo, usuarioId: null },
      });
      if (existingPatient) {
        await this.prisma.patient.update({
          where: { id: existingPatient.id },
          data: { usuarioId: user.id },
        });
      } else {
        await this.prisma.patient.create({
          data: {
            nombre,
            correo,
            usuarioId: user.id,
          },
        });
      }
      await this.prisma.invitation.updateMany({
        where: { correo, estado: 'PENDIENTE', pacienteUsuarioId: null },
        data: { pacienteUsuarioId: user.id },
      });
    }

    return this.issueSession(user);
  }

  async login(dto: LoginDto, context: LoginContext = {}): Promise<AuthResponseDto> {
    const correo = dto.correo.trim().toLowerCase();
    const attemptKeys = this.loginAttemptKeys(correo, context);
    for (const key of attemptKeys) await this.assertLoginAllowed(key);
    const user = await this.prisma.user.findUnique({ where: { correo } });

    if (!user) {
      await Promise.all(attemptKeys.map((key) => this.recordLoginFailure(key)));
      throw new UnauthorizedException('Credenciales incorrectas');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      await Promise.all(attemptKeys.map((key) => this.recordLoginFailure(key)));
      throw new UnauthorizedException('Credenciales incorrectas');
    }

    await Promise.all(attemptKeys.map((key) => this.clearLoginFailures(key)));
    return this.issueSession(user, context);
  }

  async refresh(dto: RefreshTokenDto, context: LoginContext = {}): Promise<AuthResponseDto> {
    const payload = await this.verifyRefreshToken(dto.refreshToken);
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user) {
      throw new UnauthorizedException('Sesión inválida');
    }

    if (payload.sid && this.prisma.authSession) {
      const session = await this.prisma.authSession.findUnique({
        where: { id: payload.sid },
      });
      if (
        !session ||
        session.userId !== user.id ||
        session.revokedAt ||
        session.expiresAt <= new Date()
      ) {
        throw new UnauthorizedException('Sesión inválida');
      }
      const matches = await bcrypt.compare(dto.refreshToken, session.tokenHash);
      if (!matches) {
        throw new UnauthorizedException('Sesión inválida');
      }
      // The refresh token is stable for this session. This makes simultaneous
      // refresh requests safe instead of invalidating each other by rotation.
      return this.issueSession(user, context, {
        id: session.id,
        refreshToken: dto.refreshToken,
      });
    }

    if (!user.refreshTokenHash) {
      throw new UnauthorizedException('Sesión inválida');
    }
    const matches = await bcrypt.compare(dto.refreshToken, user.refreshTokenHash);
    if (!matches) {
      throw new UnauthorizedException('Sesión inválida');
    }

    return this.issueSession(user, context);
  }

  async logout(dto: LogoutDto): Promise<{ success: boolean }> {
    try {
      const payload = await this.verifyRefreshToken(dto.refreshToken);
      if (payload.sid && this.prisma.authSession) {
        await this.prisma.authSession.updateMany({
          where: { id: payload.sid, userId: payload.sub, revokedAt: null },
          data: { revokedAt: new Date() },
        });
      } else {
        await this.prisma.user.updateMany({
          where: { id: payload.sub },
          data: { refreshTokenHash: null },
        });
      }
    } catch (_) {
      return { success: true };
    }

    return { success: true };
  }

  async listSessions(userId: number) {
    if (!this.prisma.authSession) return [];
    return this.prisma.authSession.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { lastUsedAt: 'desc' },
      select: {
        id: true,
        userAgent: true,
        ipAddress: true,
        createdAt: true,
        lastUsedAt: true,
        expiresAt: true,
      },
    });
  }

  async revokeSession(userId: number, sessionId: string) {
    if (this.prisma.authSession) {
      await this.prisma.authSession.updateMany({
        where: { id: sessionId, userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { success: true };
  }

  async revokeAllSessions(userId: number) {
    if (this.prisma.authSession) {
      await this.prisma.authSession.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    await this.prisma.user.updateMany({
      where: { id: userId },
      data: { refreshTokenHash: null },
    });
    return { success: true };
  }

  private async issueSession(
    user: User,
    context: LoginContext = {},
    existing?: { id: string; refreshToken: string },
  ): Promise<AuthResponseDto> {
    const sessionId = existing?.id ?? randomUUID();
    const payload = this.buildPayload(user, sessionId);
    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.accessSecret(),
      expiresIn: this.accessExpiresIn() as any,
    });
    const refreshToken = existing?.refreshToken ??
      (await this.jwtService.signAsync(payload, {
        secret: this.refreshSecret(),
        expiresIn: this.refreshExpiresIn() as any,
      }));

    if (this.prisma.authSession) {
      if (existing) {
        await this.prisma.authSession.update({
          where: { id: existing.id },
          data: { lastUsedAt: new Date() },
        });
      } else {
        await this.prisma.authSession.create({
          data: {
            id: sessionId,
            userId: user.id,
            tokenHash: await bcrypt.hash(refreshToken, SALT_ROUNDS),
            userAgent: context.userAgent ?? '',
            ipAddress: context.ipAddress ?? '',
            expiresAt: this.refreshExpiryDate(),
          },
        });
      }
    } else {
      const refreshTokenHash = await bcrypt.hash(refreshToken, SALT_ROUNDS);
      await this.prisma.user.update({
        where: { id: user.id },
        data: { refreshTokenHash },
      });
    }

    return {
      success: true,
      accessToken,
      refreshToken,
      usuario: {
        id: user.id,
        nombre: user.nombre,
        correo: user.correo,
        rol: this.fromPrismaRole(user.rol),
      },
    };
  }

  private buildPayload(user: User, sid?: string): JwtPayload {
    return {
      sub: user.id,
      correo: user.correo,
      rol: this.fromPrismaRole(user.rol),
      nombre: user.nombre,
      ...(sid ? { sid } : {}),
    };
  }

  private async assertLoginAllowed(key: string) {
    const attempts = this.prisma.loginAttempt;
    if (!attempts) return;
    const current = await attempts.findUnique({ where: { key } });
    if (current?.blockedUntil && current.blockedUntil > new Date()) {
      throw new HttpException(
        'Demasiados intentos. Intenta nuevamente en unos minutos.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    if (current && Date.now() - current.windowStart.getTime() >= LOGIN_WINDOW_MS) {
      await attempts.update({
        where: { key },
        data: { failures: 0, windowStart: new Date(), blockedUntil: null },
      });
    }
  }

  private loginAttemptKeys(correo: string, context: LoginContext): string[] {
    const keys = [`correo:${correo}:${context.ipAddress ?? 'unknown'}`];
    if (context.ipAddress) keys.push(`ip:${context.ipAddress}`);
    return keys;
  }

  private async recordLoginFailure(key: string) {
    const attempts = this.prisma.loginAttempt;
    if (!attempts) return;
    const current = await attempts.findUnique({ where: { key } });
    const now = new Date();
    if (!current || now.getTime() - current.windowStart.getTime() >= LOGIN_WINDOW_MS) {
      await attempts.upsert({
        where: { key },
        create: { key, failures: 1, windowStart: now },
        update: { failures: 1, windowStart: now, blockedUntil: null },
      });
      return;
    }
    const failures = current.failures + 1;
    await attempts.update({
      where: { key },
      data: {
        failures,
        blockedUntil: failures >= MAX_LOGIN_FAILURES
          ? new Date(now.getTime() + LOGIN_BLOCK_MS)
          : null,
      },
    });
  }

  private async clearLoginFailures(key: string) {
    const attempts = this.prisma.loginAttempt;
    if (attempts) await attempts.deleteMany({ where: { key } });
  }

  private refreshExpiryDate(): Date {
    return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  }

  private async verifyRefreshToken(token: string): Promise<JwtPayload> {
    try {
      return await this.jwtService.verifyAsync<JwtPayload>(token, {
        secret: this.refreshSecret(),
      });
    } catch (_) {
      throw new UnauthorizedException('Sesión inválida');
    }
  }

  private accessSecret(): string {
    return this.configService.get<string>('JWT_ACCESS_SECRET') ?? 'change-me-access-secret';
  }

  private refreshSecret(): string {
    return this.configService.get<string>('JWT_REFRESH_SECRET') ?? 'change-me-refresh-secret';
  }

  private accessExpiresIn(): string {
    return this.configService.get<string>('JWT_ACCESS_EXPIRES_IN') ?? '15m';
  }

  private refreshExpiresIn(): string {
    return this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '7d';
  }

  private toPrismaRole(role: 'nutricionista' | 'paciente'): UserRole {
    return role === 'nutricionista' ? UserRole.NUTRICIONISTA : UserRole.PACIENTE;
  }

  private fromPrismaRole(role: UserRole): 'nutricionista' | 'paciente' {
    return role === UserRole.NUTRICIONISTA ? 'nutricionista' : 'paciente';
  }
}
