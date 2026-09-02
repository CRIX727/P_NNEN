import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './modules/auth/auth.module';
import { NutricionistaModule } from './modules/nutricionista/nutricionista.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    NutricionistaModule,
  ],
})
export class AppModule {}
