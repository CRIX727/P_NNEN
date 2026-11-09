import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from './jwt-auth.guard';
import { PushService } from './push.service';

@UseGuards(JwtAuthGuard)
@Controller('auth')
export class DeviceController {
  constructor(private readonly push: PushService) {}

  @Post('device')
  register(@Req() request: any, @Body() body: { token?: string; plataforma?: string }) {
    if (!body.token?.trim()) return { success: false, message: 'Token requerido' };
    return this.push.registerToken(request.user.sub, body.token, body.plataforma);
  }

  @Post('device/remove')
  async remove(@Req() request: any, @Body() body: { token?: string }) {
    if (body.token?.trim()) await this.push.removeToken(request.user.sub, body.token);
    return { success: true };
  }
}
