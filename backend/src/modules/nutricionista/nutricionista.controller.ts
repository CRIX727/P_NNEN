import { Body, Controller, Get, Param, ParseIntPipe, Post, Put, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../../common/jwt-auth.guard';
import {
  CreateAppointmentDto,
  CreateDocumentDto,
  CreateEvaluationDto,
  CreateMessageDto,
  CreatePatientDto,
  CreatePaymentDto,
  CreatePlanDto,
  CreateTemplateDto,
  UpdatePatientDto,
  UpdateSettingsDto,
} from './dto/nutricionista.dto';
import { NutricionistaService } from './nutricionista.service';

@UseGuards(JwtAuthGuard)
@Controller('nutricionista')
export class NutricionistaController {
  constructor(private readonly service: NutricionistaService) {}

  @Get('dashboard')
  dashboard(@Req() req: any) {
    return this.service.dashboard(req.user.sub);
  }

  @Get('pacientes')
  listPatients(@Req() req: any) {
    return this.service.listPatients(req.user.sub);
  }

  @Post('pacientes')
  createPatient(@Req() req: any, @Body() dto: CreatePatientDto) {
    return this.service.createPatient(req.user.sub, dto);
  }

  @Get('pacientes/:id')
  getPatient(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.getPatient(id, req.user.sub);
  }

  @Put('pacientes/:id')
  updatePatient(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: UpdatePatientDto) {
    return this.service.updatePatient(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/evaluaciones')
  listEvaluations(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listEvaluations(id, req.user.sub);
  }

  @Post('pacientes/:id/evaluaciones')
  createEvaluation(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateEvaluationDto) {
    return this.service.createEvaluation(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/planes')
  listPlans(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listPlans(id, req.user.sub);
  }

  @Post('pacientes/:id/planes')
  createPlan(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreatePlanDto) {
    return this.service.createPlan(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/citas')
  listAppointments(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listAppointments(id, req.user.sub);
  }

  @Post('pacientes/:id/citas')
  createAppointment(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateAppointmentDto) {
    return this.service.createAppointment(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/mensajes')
  listMessages(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listMessages(id, req.user.sub);
  }

  @Post('pacientes/:id/mensajes')
  createMessage(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateMessageDto) {
    return this.service.createMessage(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/pagos')
  listPayments(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listPayments(id, req.user.sub);
  }

  @Post('pacientes/:id/pagos')
  createPayment(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreatePaymentDto) {
    return this.service.createPayment(id, req.user.sub, dto);
  }

  @Get('pacientes/:id/documentos')
  listDocuments(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listDocuments(id, req.user.sub);
  }

  @Post('pacientes/:id/documentos')
  createDocument(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateDocumentDto) {
    return this.service.createDocument(id, req.user.sub, dto);
  }

  @Get('plantillas')
  listTemplates() {
    return this.service.listTemplates();
  }

  @Post('plantillas')
  createTemplate(@Body() dto: CreateTemplateDto) {
    return this.service.createTemplate(dto);
  }

  @Get('configuracion')
  getSettings(@Req() req: any) {
    return this.service.getSettings(req.user.sub);
  }

  @Put('configuracion')
  updateSettings(@Req() req: any, @Body() dto: UpdateSettingsDto) {
    return this.service.updateSettings(req.user.sub, dto);
  }
}

