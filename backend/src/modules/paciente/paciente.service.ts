import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../common/prisma.service';
import { CreatePatientMessageDto } from './dto/paciente.dto';

type PatientSession = {
  correo: string;
  rol: 'nutricionista' | 'paciente';
};

@Injectable()
export class PacienteService {
  constructor(private readonly prisma: PrismaService) {}

  private async getPatient(session: PatientSession) {
    if (session.rol !== 'paciente') {
      throw new ForbiddenException('Esta sección es exclusiva para pacientes');
    }

    const patient = await this.prisma.patient.findFirst({
      where: { correo: session.correo.toLowerCase() },
      include: {
        nutricionista: {
          select: { id: true, nombre: true, correo: true, whatsapp: true },
        },
      },
    });

    if (!patient) {
      throw new NotFoundException(
        'Aún no existe una ficha de paciente asociada a este correo',
      );
    }

    return patient;
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
}
