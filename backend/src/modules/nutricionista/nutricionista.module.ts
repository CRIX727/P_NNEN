import { Module } from '@nestjs/common';

import { CommonModule } from '../../common/common.module';
import { NutricionistaController } from './nutricionista.controller';
import { NutricionistaService } from './nutricionista.service';

@Module({
  imports: [CommonModule],
  controllers: [NutricionistaController],
  providers: [NutricionistaService],
})
export class NutricionistaModule {}

