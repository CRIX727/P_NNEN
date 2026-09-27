import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './modules/auth/auth.module';
import { NutricionistaModule } from './modules/nutricionista/nutricionista.module';
import { PacienteModule } from './modules/paciente/paciente.module';
import { ChatModule } from './modules/chat/chat.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    NutricionistaModule,
    PacienteModule,
    ChatModule,
  ],
})
export class AppModule {}
