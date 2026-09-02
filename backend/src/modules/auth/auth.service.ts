import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AppointmentStatus, PaymentStatus, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../../common/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';

const SALT_ROUNDS = 10;

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

    return this.issueSession(user);
  }

  async login(dto: LoginDto): Promise<AuthResponseDto> {
    const correo = dto.correo.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { correo } });

    if (!user) {
      throw new UnauthorizedException('Credenciales incorrectas');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Credenciales incorrectas');
    }

    return this.issueSession(user);
  }

  async refresh(dto: RefreshTokenDto): Promise<AuthResponseDto> {
    const payload = await this.verifyRefreshToken(dto.refreshToken);
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedException('Sesión inválida');
    }

    const matches = await bcrypt.compare(dto.refreshToken, user.refreshTokenHash);
    if (!matches) {
      throw new UnauthorizedException('Sesión inválida');
    }

    return this.issueSession(user);
  }

  async logout(dto: LogoutDto): Promise<{ success: boolean }> {
    try {
      const payload = await this.verifyRefreshToken(dto.refreshToken);
      await this.prisma.user.updateMany({
        where: { id: payload.sub },
        data: { refreshTokenHash: null },
      });
    } catch (_) {
      return { success: true };
    }

    return { success: true };
  }

  private async issueSession(user: User): Promise<AuthResponseDto> {
    const payload = this.buildPayload(user);
    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.accessSecret(),
      expiresIn: this.accessExpiresIn() as any,
    });
    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: this.refreshSecret(),
      expiresIn: this.refreshExpiresIn() as any,
    });

    const refreshTokenHash = await bcrypt.hash(refreshToken, SALT_ROUNDS);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { refreshTokenHash },
    });

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

  private buildPayload(user: User): JwtPayload {
    return {
      sub: user.id,
      correo: user.correo,
      rol: this.fromPrismaRole(user.rol),
      nombre: user.nombre,
    };
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
