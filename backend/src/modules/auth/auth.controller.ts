import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { Throttle } from '@nestjs/throttler';

import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtAuthGuard } from '../../common/jwt-auth.guard';
import { JwtPayload } from './interfaces/jwt-payload.interface';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 8, ttl: 60_000, blockDuration: 60_000 } })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @Throttle({ default: { limit: 10, ttl: 60_000, blockDuration: 60_000 } })
  login(@Body() dto: LoginDto, @Req() request: Request) {
    return this.authService.login(dto, {
      ipAddress: request.ip,
      userAgent: request.get('user-agent') ?? '',
    });
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto, @Req() request: Request) {
    return this.authService.refresh(dto, {
      ipAddress: request.ip,
      userAgent: request.get('user-agent') ?? '',
    });
  }

  @Post('logout')
  logout(@Body() dto: LogoutDto) {
    return this.authService.logout(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('sessions')
  sessions(@Req() request: Request & { user: JwtPayload }) {
    return this.authService.listSessions(request.user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('sessions/:id')
  revokeSession(
    @Req() request: Request & { user: JwtPayload },
    @Param('id') id: string,
  ) {
    return this.authService.revokeSession(request.user.sub, id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('sessions/revoke-all')
  revokeAllSessions(@Req() request: Request & { user: JwtPayload }) {
    return this.authService.revokeAllSessions(request.user.sub);
  }
}

