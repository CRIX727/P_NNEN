import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../../common/jwt-auth.guard';
import { CreatePatientMessageDto } from './dto/paciente.dto';
import { PacienteService } from './paciente.service';

@UseGuards(JwtAuthGuard)
@Controller('paciente')
export class PacienteController {
  constructor(private readonly service: PacienteService) {}

  @Get('dashboard')
  dashboard(@Req() req: any) {
    return this.service.dashboard(req.user);
  }

  @Get('perfil')
  profile(@Req() req: any) {
    return this.service.profile(req.user);
  }

  @Get('evaluaciones')
  evaluations(@Req() req: any) {
    return this.service.listEvaluations(req.user);
  }

  @Get('planes')
  plans(@Req() req: any) {
    return this.service.listPlans(req.user);
  }

  @Get('citas')
  appointments(@Req() req: any) {
    return this.service.listAppointments(req.user);
  }

  @Get('mensajes')
  messages(@Req() req: any) {
    return this.service.listMessages(req.user);
  }

  @Post('mensajes')
  sendMessage(@Req() req: any, @Body() dto: CreatePatientMessageDto) {
    return this.service.createMessage(req.user, dto);
  }

  @Get('pagos')
  payments(@Req() req: any) {
    return this.service.listPayments(req.user);
  }

  @Get('documentos')
  documents(@Req() req: any) {
    return this.service.listDocuments(req.user);
  }
}
