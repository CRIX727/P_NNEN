import { BadRequestException, Body, Controller, Get, Param, ParseIntPipe, Post, Req, UseGuards } from '@nestjs/common';

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

  @Get('invitaciones')
  invitations(@Req() req: any) {
    return this.service.listInvitations(req.user);
  }

  @Post('invitaciones/:id/aceptar')
  acceptInvitation(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.acceptInvitation(req.user, id);
  }

  @Post('invitaciones/:id/rechazar')
  rejectInvitation(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.rejectInvitation(req.user, id);
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

  @Get('consultas')
  consultations(@Req() req: any) {
    return this.service.listConsultations(req.user);
  }

  @Get('suscripcion')
  subscription(@Req() req: any) {
    return this.service.getSubscription(req.user);
  }

  @Post('suscripcion')
  createSubscription(@Req() req: any, @Body() body: { plan?: string }) {
    return this.service.createSubscription(req.user, body.plan ?? 'BASICO');
  }

  @Post('suscripcion/cancelar')
  cancelSubscription(@Req() req: any) {
    return this.service.cancelSubscription(req.user);
  }

  @Get('notificaciones')
  notifications(@Req() req: any) {
    return this.service.listNotifications(req.user);
  }

  @Post('notificaciones/:id/leer')
  markNotificationRead(@Req() req: any, @Param('id', ParseIntPipe) id: number) {
    return this.service.markNotificationRead(req.user, id);
  }

  @Post('notificaciones/leer-todas')
  markAllNotificationsRead(@Req() req: any) {
    return this.service.markAllNotificationsRead(req.user);
  }

  @Post('dispositivo')
  registerDevice(@Req() req: any, @Body() body: { token?: string; plataforma?: string }) {
    if (!body.token?.trim()) throw new BadRequestException('El token del dispositivo es obligatorio');
    return this.service.registerDeviceToken(req.user, body.token, body.plataforma);
  }

  @Post('dispositivo/eliminar')
  removeDevice(@Req() req: any, @Body() body: { token?: string }) {
    if (!body.token?.trim()) throw new BadRequestException('El token del dispositivo es obligatorio');
    return this.service.removeDeviceToken(req.user, body.token);
  }
}
