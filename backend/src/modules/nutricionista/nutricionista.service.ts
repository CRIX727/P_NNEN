import { Injectable, NotFoundException } from '@nestjs/common';
import { AppointmentStatus, PaymentStatus } from '@prisma/client';

import { PrismaService } from '../../common/prisma.service';
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

@Injectable()
export class NutricionistaService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboard(nutricionistaId: number) {
    const [patients, evaluations, payments, plans, appointments, messages] = await Promise.all([
      this.prisma.patient.findMany({ where: { nutricionistaId } }),
      this.prisma.evaluation.findMany({
        where: { patient: { nutricionistaId } },
        include: { patient: true },
      }),
      this.prisma.payment.findMany({
        where: { patient: { nutricionistaId } },
        include: { patient: true },
      }),
      this.prisma.plan.findMany({ where: { patient: { nutricionistaId } } }),
      this.prisma.appointment.findMany({
        where: { patient: { nutricionistaId } },
        include: { patient: true },
      }),
      this.prisma.message.findMany({
        where: { patient: { nutricionistaId } },
        include: { patient: true },
      }),
    ]);

    const averageImc =
      evaluations.length > 0
        ? evaluations.reduce((sum, item) => sum + item.imc, 0) / evaluations.length
        : 0;

    const pendingPayments = payments.filter((item) => item.estado === PaymentStatus.PENDIENTE).length;

    return {
      totalPacientes: patients.length,
      totalEvaluaciones: evaluations.length,
      totalPlanes: plans.length,
      totalCitas: appointments.length,
      totalMensajes: messages.length,
      pagosPendientes: pendingPayments,
      imcPromedio: averageImc,
    };
  }

  async listPatients(nutricionistaId: number) {
    return this.prisma.patient.findMany({
      where: { nutricionistaId },
      orderBy: { nombre: 'asc' },
    });
  }

  async getPatient(id: number, nutricionistaId: number) {
    const patient = await this.prisma.patient.findFirst({
      where: { id, nutricionistaId },
    });
    if (!patient) {
      throw new NotFoundException('Paciente no encontrado');
    }
    return patient;
  }

  async createPatient(nutricionistaId: number, dto: CreatePatientDto) {
    return this.prisma.patient.create({
      data: {
        nutricionistaId,
        nombre: dto.nombre.trim(),
        correo: dto.correo.trim().toLowerCase(),
        peso: dto.peso,
        altura: dto.altura,
        grasaCorporal: dto.grasaCorporal,
        alergias: dto.alergias,
        enfermedades: dto.enfermedades,
        edad: dto.edad,
        sexo: dto.sexo,
        factorActividad: dto.factorActividad,
        telefono: dto.telefono,
        notas: dto.notas,
      },
    });
  }

  async updatePatient(id: number, nutricionistaId: number, dto: UpdatePatientDto) {
    await this.getPatient(id, nutricionistaId);
    return this.prisma.patient.update({
      where: { id },
      data: {
        nombre: dto.nombre.trim(),
        correo: dto.correo.trim().toLowerCase(),
        peso: dto.peso,
        altura: dto.altura,
        grasaCorporal: dto.grasaCorporal,
        alergias: dto.alergias,
        enfermedades: dto.enfermedades,
        edad: dto.edad,
        sexo: dto.sexo,
        factorActividad: dto.factorActividad,
        telefono: dto.telefono,
        notas: dto.notas,
      },
    });
  }

  async listEvaluations(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.evaluation.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createEvaluation(
    pacienteId: number,
    nutricionistaId: number,
    dto: CreateEvaluationDto,
  ) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    const imc = dto.altura > 0 ? dto.peso / (dto.altura * dto.altura) : 0;
    const tmb = this.calculateTmb(dto.peso, patient.altura * 100, patient.edad, patient.sexo);
    const get = tmb * patient.factorActividad;

    await this.prisma.patient.update({
      where: { id: pacienteId },
      data: {
        peso: dto.peso,
        altura: dto.altura,
        grasaCorporal: dto.grasa,
      },
    });

    return this.prisma.evaluation.create({
      data: {
        pacienteId,
        peso: dto.peso,
        altura: dto.altura,
        imc,
        tmb,
        get,
        grasa: dto.grasa,
        fecha: dto.fecha,
      },
    });
  }

  async listPlans(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.plan.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createPlan(pacienteId: number, nutricionistaId: number, dto: CreatePlanDto) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.plan.create({
      data: {
        pacienteId,
        titulo: dto.titulo,
        descripcion: dto.descripcion,
        objetivo: dto.objetivo,
        condicion: dto.condicion,
        plantillaNombre: dto.plantillaNombre,
        fechaInicio: dto.fechaInicio,
        fechaFin: dto.fechaFin,
      },
    });
  }

  async listAppointments(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.appointment.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createAppointment(
    pacienteId: number,
    nutricionistaId: number,
    dto: CreateAppointmentDto,
  ) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.appointment.create({
      data: {
        pacienteId,
        fecha: dto.fecha,
        motivo: dto.motivo,
        estado: dto.estado as AppointmentStatus,
        canalRecordatorio: dto.canalRecordatorio,
      },
    });
  }

  async listMessages(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.message.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createMessage(pacienteId: number, nutricionistaId: number, dto: CreateMessageDto) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.message.create({
      data: {
        pacienteId,
        remitente: dto.remitente,
        contenido: dto.contenido,
        fecha: dto.fecha,
      },
    });
  }

  async listPayments(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.payment.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createPayment(pacienteId: number, nutricionistaId: number, dto: CreatePaymentDto) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.payment.create({
      data: {
        pacienteId,
        monto: dto.monto,
        concepto: dto.concepto,
        fecha: dto.fecha,
        estado: dto.estado as PaymentStatus,
      },
    });
  }

  async listDocuments(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.document.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createDocument(pacienteId: number, nutricionistaId: number, dto: CreateDocumentDto) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.document.create({
      data: {
        pacienteId,
        nombre: dto.nombre,
        tipo: dto.tipo,
        uri: dto.uri,
        fecha: dto.fecha,
      },
    });
  }

  async listTemplates() {
    return this.prisma.planTemplate.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async createTemplate(dto: CreateTemplateDto) {
    return this.prisma.planTemplate.create({
      data: {
        nombre: dto.nombre,
        objetivo: dto.objetivo,
        condicion: dto.condicion,
        descripcion: dto.descripcion,
      },
    });
  }

  async getSettings(nutricionistaId: number) {
    const user = await this.prisma.user.findUnique({ where: { id: nutricionistaId } });
    if (!user) {
      throw new NotFoundException('Usuario no encontrado');
    }

    return {
      precioConsulta: user.precioConsulta ?? 0,
      whatsapp: user.whatsapp ?? '',
    };
  }

  async updateSettings(nutricionistaId: number, dto: UpdateSettingsDto) {
    return this.prisma.user.update({
      where: { id: nutricionistaId },
      data: {
        ...(dto.precioConsulta !== undefined ? { precioConsulta: dto.precioConsulta } : {}),
        ...(dto.whatsapp !== undefined ? { whatsapp: dto.whatsapp } : {}),
      },
    });
  }

  private calculateTmb(peso: number, alturaCm: number, edad: number, sexo: string) {
    const adjustment = sexo.toLowerCase().includes('masc') ? 5 : -161;
    return (10 * peso) + (6.25 * alturaCm) - (5 * edad) + adjustment;
  }
}
