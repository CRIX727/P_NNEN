import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InvitationStatus, UserRole } from '@prisma/client';

import { PrismaService } from '../../common/prisma.service';
import { PushService } from '../../common/push.service';
import { CreatePatientMessageDto } from './dto/paciente.dto';

type PatientSession = {
  sub: number;
  correo: string;
  rol: 'nutricionista' | 'paciente';
};

@Injectable()
export class PacienteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

  private async getPatient(session: PatientSession) {
    if (session.rol !== 'paciente') {
      throw new ForbiddenException('Esta sección es exclusiva para pacientes');
    }

    const patient = await this.prisma.patient.findFirst({
      where: {
        OR: [
          { usuarioId: session.sub },
          { correo: session.correo.toLowerCase(), usuarioId: null },
        ],
      },
      include: {
        nutricionista: {
          select: { id: true, nombre: true, correo: true, whatsapp: true },
        },
      },
    });

    if (!patient) throw new NotFoundException('No existe una ficha de paciente para esta cuenta');

    return patient;
  }

  async listInvitations(session: PatientSession) {
    this.assertPatient(session);
    return this.prisma.invitation.findMany({
      where: {
        estado: InvitationStatus.PENDIENTE,
        OR: [{ pacienteUsuarioId: session.sub }, { correo: session.correo.toLowerCase() }],
      },
      orderBy: { createdAt: 'desc' },
      include: { nutricionista: { select: { id: true, nombre: true, correo: true, whatsapp: true } } },
    });
  }

  async acceptInvitation(session: PatientSession, invitationId: number) {
    this.assertPatient(session);
    const invitation = await this.prisma.invitation.findFirst({
      where: {
        id: invitationId,
        estado: InvitationStatus.PENDIENTE,
        OR: [{ pacienteUsuarioId: session.sub }, { correo: session.correo.toLowerCase() }],
      },
    });
    if (!invitation) throw new NotFoundException('Invitación no encontrada o ya procesada');

    const current = await this.prisma.patient.findFirst({
      where: { OR: [{ usuarioId: session.sub }, { correo: session.correo.toLowerCase(), usuarioId: null }] },
    });
    if (current?.nutricionistaId && current.nutricionistaId !== invitation.nutricionistaId) {
      throw new BadRequestException('Esta cuenta ya está vinculada a otro nutricionista');
    }

    const patient = current
      ? await this.prisma.patient.update({
          where: { id: current.id },
          data: { nutricionistaId: invitation.nutricionistaId, usuarioId: session.sub },
          include: { nutricionista: { select: { id: true, nombre: true, correo: true, whatsapp: true } } },
        })
      : await this.prisma.patient.create({
          data: {
            nombre: session.correo.split('@')[0],
            correo: session.correo.toLowerCase(),
            nutricionistaId: invitation.nutricionistaId,
            usuarioId: session.sub,
          },
          include: { nutricionista: { select: { id: true, nombre: true, correo: true, whatsapp: true } } },
        });

    await this.prisma.invitation.update({
      where: { id: invitation.id },
      data: { estado: InvitationStatus.ACEPTADA, pacienteUsuarioId: session.sub },
    });
    return { paciente: patient, nutricionista: patient.nutricionista };
  }

  async rejectInvitation(session: PatientSession, invitationId: number) {
    this.assertPatient(session);
    const invitation = await this.prisma.invitation.findFirst({
      where: {
        id: invitationId,
        estado: InvitationStatus.PENDIENTE,
        OR: [{ pacienteUsuarioId: session.sub }, { correo: session.correo.toLowerCase() }],
      },
    });
    if (!invitation) throw new NotFoundException('Invitación no encontrada o ya procesada');
    return this.prisma.invitation.update({ where: { id: invitation.id }, data: { estado: InvitationStatus.RECHAZADA } });
  }

  private assertPatient(session: PatientSession) {
    if (session.rol !== 'paciente') throw new ForbiddenException('Esta sección es exclusiva para pacientes');
  }

  async dashboard(session: PatientSession) {
    const patient = await this.getPatient(session);
    const [evaluaciones, planes, citas, mensajes, pagos] = await Promise.all([
      this.prisma.evaluation.findMany({
        where: { pacienteId: patient.id },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.plan.findMany({
        where: { pacienteId: patient.id },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.appointment.findMany({
        where: { pacienteId: patient.id },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.message.findMany({
        where: { pacienteId: patient.id },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.payment.findMany({
        where: { pacienteId: patient.id },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    return {
      paciente: patient,
      nutricionista: patient.nutricionista,
      evaluaciones,
      planes,
      citas,
      mensajes,
      pagos,
    };
  }

  async profile(session: PatientSession) {
    const patient = await this.getPatient(session);
    return { paciente: patient, nutricionista: patient.nutricionista };
  }

  async listEvaluations(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.evaluation.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'asc' },
    });
  }

  async listPlans(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.plan.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listAppointments(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.appointment.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listMessages(session: PatientSession) {
    const patient = await this.getPatient(session);
    await this.prisma.message.updateMany({
      where: { pacienteId: patient.id, remitente: 'nutricionista', leido: false },
      data: { leido: true, leidoAt: new Date() },
    });
    return this.prisma.message.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createMessage(session: PatientSession, dto: CreatePatientMessageDto) {
    const patient = await this.getPatient(session);
    return this.prisma.message.create({
      data: {
        pacienteId: patient.id,
        remitente: 'paciente',
        contenido: dto.contenido.trim(),
        fecha: dto.fecha?.trim() || new Date().toISOString(),
      },
    });
  }

  async listPayments(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.payment.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listDocuments(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.document.findMany({
      where: { pacienteId: patient.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listConsultations(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.consultation.findMany({
      where: { pacienteId: patient.id },
      orderBy: { fecha: 'desc' },
    });
  }

  async getSubscription(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.patientSubscription.findUnique({ where: { pacienteId: patient.id } });
  }

  async createSubscription(session: PatientSession, plan: string) {
    const patient = await this.getPatient(session);
    const validPlans = ['BASICO', 'PRO', 'PREMIUM'];
    if (!validPlans.includes(plan.toUpperCase())) {
      throw new BadRequestException('Plan de suscripción inválido');
    }
    const start = new Date();
    const end = new Date(start);
    end.setMonth(end.getMonth() + 1);
    return this.prisma.patientSubscription.upsert({
      where: { pacienteId: patient.id },
      create: {
        pacienteId: patient.id,
        plan: plan.toUpperCase(),
        estado: 'ACTIVA',
        periodoInicio: start,
        periodoFin: end,
      },
      update: {
        plan: plan.toUpperCase(),
        estado: 'ACTIVA',
        periodoInicio: start,
        periodoFin: end,
      },
    });
  }

  async cancelSubscription(session: PatientSession) {
    const patient = await this.getPatient(session);
    return this.prisma.patientSubscription.updateMany({
      where: { pacienteId: patient.id, estado: 'ACTIVA' },
      data: { estado: 'CANCELADA', periodoFin: new Date() },
    });
  }

  async listNotifications(session: PatientSession) {
    this.assertPatient(session);
    return this.prisma.notification.findMany({
      where: { userId: session.sub },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async markNotificationRead(session: PatientSession, id: number) {
    this.assertPatient(session);
    return this.prisma.notification.updateMany({
      where: { id, userId: session.sub },
      data: { leida: true, enviadaAt: new Date() },
    });
  }

  async markAllNotificationsRead(session: PatientSession) {
    this.assertPatient(session);
    return this.prisma.notification.updateMany({
      where: { userId: session.sub, leida: false },
      data: { leida: true, enviadaAt: new Date() },
    });
  }

  async registerDeviceToken(session: PatientSession, token: string, plataforma?: string) {
    this.assertPatient(session);
    return this.push.registerToken(session.sub, token.trim(), plataforma ?? 'android');
  }

  async removeDeviceToken(session: PatientSession, token: string) {
    this.assertPatient(session);
    await this.push.removeToken(session.sub, token.trim());
    return { success: true };
  }
}
