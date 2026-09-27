import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { CommonModule } from '../../common/common.module';
import { ChatGateway } from './chat.gateway';

@Module({
  imports: [CommonModule, JwtModule.register({})],
  providers: [ChatGateway],
})
export class ChatModule {}
