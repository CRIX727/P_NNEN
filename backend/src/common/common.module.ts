import { Global, Module } from '@nestjs/common';

import { PrismaService } from './prisma.service';
import { PushService } from './push.service';
import { DeviceController } from './device.controller';
import { HealthController } from './health.controller';

@Global()
@Module({
  controllers: [DeviceController, HealthController],
  providers: [PrismaService, PushService],
  exports: [PrismaService, PushService],
})
export class CommonModule {}

