import { BadRequestException, Body, Controller, Get, Param, ParseIntPipe, Post, Put, Req, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';

import { JwtAuthGuard } from '../../common/jwt-auth.guard';
import {
  CreateAppointmentDto,
  CreateDocumentDto,
  CreateEvaluationDto,
  CreateConsultationDto,
  CreateFoodDto,
  CreateInvitationDto,
  CreateMessageDto,
  CreatePatientDto,
  CreatePaymentDto,
  CreatePlanDto,
  CreateTaskDto,
  CreateTemplateDto,
  UpdateEvaluationDto,
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

  @Get('invitaciones')
  listInvitations(@Req() req: any) {
    return this.service.listInvitations(req.user.sub);
  }

  @Post('invitaciones')
  createInvitation(@Req() req: any, @Body() dto: CreateInvitationDto) {
    return this.service.createInvitation(req.user.sub, dto.correo);
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

  @Put('pacientes/:patientId/evaluaciones/:evaluationId')
  updateEvaluation(
    @Req() req: any,
    @Param('patientId', ParseIntPipe) patientId: number,
    @Param('evaluationId', ParseIntPipe) evaluationId: number,
    @Body() dto: UpdateEvaluationDto,
  ) {
    return this.service.updateEvaluation(patientId, evaluationId, req.user.sub, dto);
  }

  @Get('pacientes/:id/planes')
  listPlans(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listPlans(id, req.user.sub);
  }

  @Post('pacientes/:id/planes')
  createPlan(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreatePlanDto) {
    return this.service.createPlan(id, req.user.sub, dto);
  }

  @Put('pacientes/:patientId/planes/:planId')
  updatePlan(
    @Req() req: any,
    @Param('patientId', ParseIntPipe) patientId: number,
    @Param('planId', ParseIntPipe) planId: number,
    @Body() dto: CreatePlanDto,
  ) {
    return this.service.updatePlan(patientId, planId, req.user.sub, dto);
  }

  @Get('pacientes/:id/citas')
  listAppointments(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listAppointments(id, req.user.sub);
  }

  @Post('pacientes/:id/citas')
  createAppointment(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateAppointmentDto) {
    return this.service.createAppointment(id, req.user.sub, dto);
  }

  @Put('pacientes/:patientId/citas/:appointmentId')
  updateAppointment(
    @Req() req: any,
    @Param('patientId', ParseIntPipe) patientId: number,
    @Param('appointmentId', ParseIntPipe) appointmentId: number,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.service.updateAppointment(patientId, appointmentId, req.user.sub, dto);
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

  @Put('pacientes/:patientId/pagos/:paymentId')
  updatePayment(
    @Req() req: any,
    @Param('patientId', ParseIntPipe) patientId: number,
    @Param('paymentId', ParseIntPipe) paymentId: number,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.service.updatePayment(patientId, paymentId, req.user.sub, dto);
  }

  @Get('pacientes/:id/documentos')
  listDocuments(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listDocuments(id, req.user.sub);
  }

  @Get('pacientes/:id/consultas')
  listConsultations(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.listConsultations(id, req.user.sub);
  }

  @Post('pacientes/:id/consultas')
  createConsultation(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateConsultationDto) {
    return this.service.createConsultation(id, req.user.sub, dto);
  }

  @Post('pacientes/:id/documentos')
  createDocument(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateDocumentDto) {
    return this.service.createDocument(id, req.user.sub, dto);
  }

  @Post('pacientes/:id/documentos/upload')
  @UseInterceptors(FileInterceptor('archivo', {
    storage: diskStorage({
      destination: (_request, _file, callback) => {
        const directory = 'uploads';
        if (!existsSync(directory)) mkdirSync(directory, { recursive: true });
        callback(null, directory);
      },
      filename: (_request, file, callback) => {
        const safeName = file.originalname
          .replace(/[^a-zA-Z0-9._-]/g, '_')
          .replace(/\.+/g, '.');
        callback(null, `${Date.now()}-${safeName}`);
      },
    }),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (_request, file, callback) => {
      const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
      callback(null, allowed.includes(file.mimetype));
    },
  }))
  uploadDocument(
    @Req() req: any,
    @Param('id', ParseIntPipe) id: number,
    @UploadedFile() file: Express.Multer.File,
    @Body('nombre') nombre?: string,
  ) {
    if (!file) throw new BadRequestException('Adjunta un PDF o una imagen válida');
    return this.service.createUploadedDocument(id, req.user.sub, file, nombre);
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

  @Get('alimentos')
  listFoods(@Req() req: any) {
    return this.service.listFoods(req.user.sub);
  }

  @Post('alimentos')
  createFood(@Req() req: any, @Body() dto: CreateFoodDto) {
    return this.service.createFood(req.user.sub, dto);
  }

  @Get('tareas')
  listTasks(@Req() req: any) {
    return this.service.listTasks(req.user.sub);
  }

  @Post('tareas')
  createTask(@Req() req: any, @Body() dto: CreateTaskDto) {
    return this.service.createTask(req.user.sub, dto);
  }

  @Put('tareas/:id')
  updateTask(@Req() req: any, @Param('id', ParseIntPipe) id: number, @Body() dto: CreateTaskDto) {
    return this.service.updateTask(req.user.sub, id, dto);
  }

  @Get('historial-cambios')
  listChangeLogs(@Req() req: any) {
    return this.service.listChangeLogs(req.user.sub);
  }
}

