import { Controller, Get } from '@nestjs/common';

import { PrismaService } from './prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async check() {
    const startedAt = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        database: 'ok',
        service: 'nnen-backend',
        timestamp: new Date().toISOString(),
        latencyMs: Date.now() - startedAt,
      };
    } catch {
      return {
        status: 'degraded',
        database: 'unavailable',
        service: 'nnen-backend',
        timestamp: new Date().toISOString(),
        latencyMs: Date.now() - startedAt,
      };
    }
  }
}
