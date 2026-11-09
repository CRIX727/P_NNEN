import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AppointmentStatus, InvitationStatus, PaymentStatus } from '@prisma/client';

import { PrismaService } from '../../common/prisma.service';
import { PushService } from '../../common/push.service';
import {
  CreateAppointmentDto,
  CreateDocumentDto,
  CreateEvaluationDto,
  CreateConsultationDto,
  CreateFoodDto,
  CreateMessageDto,
  CreatePatientDto,
  CreatePaymentDto,
  CreatePlanDto,
  CreateTaskDto,
  CreateTemplateDto,
  UpdatePatientDto,
  UpdateSettingsDto,
} from './dto/nutricionista.dto';

@Injectable()
export class NutricionistaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushService,
  ) {}

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
    const today = new Date().toISOString().slice(0, 10);
    const citasProximas = appointments.filter(
      (item) => item.fecha >= today && item.estado !== AppointmentStatus.CANCELADA,
    ).length;
    const pacientesEnRiesgo = patients.filter((item) => {
      const conditions = item.enfermedades.toLowerCase();
      return ['diabet', 'hipertens', 'obes', 'renal'].some((term) => conditions.includes(term));
    }).length;
    const pacientesNuevos = patients.filter(
      (item) => item.createdAt.toISOString().slice(0, 10) === today,
    ).length;

    return {
      totalPacientes: patients.length,
      totalEvaluaciones: evaluations.length,
      totalPlanes: plans.length,
      totalCitas: appointments.length,
      totalMensajes: messages.length,
      pagosPendientes: pendingPayments,
      imcPromedio: averageImc,
      pacientesNuevos,
      pacientesEnRiesgo,
      citasProximas,
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
    const correo = dto.correo.trim().toLowerCase();
    const existing = await this.prisma.patient.findFirst({
      where: { correo, OR: [{ nutricionistaId }, { nutricionistaId: null }] },
    });
    const data = {
      nutricionistaId,
      nombre: dto.nombre.trim(),
      correo,
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
      motivoConsulta: dto.motivoConsulta ?? '',
      antecedentesFamiliares: dto.antecedentesFamiliares ?? '',
      historialMedico: dto.historialMedico ?? '',
      medicamentos: dto.medicamentos ?? '',
      habitosAlimenticios: dto.habitosAlimenticios ?? '',
      consumoAgua: dto.consumoAgua ?? '',
      actividadFisica: dto.actividadFisica ?? '',
      objetivos: dto.objetivos ?? '',
      notasPrivadas: dto.notasPrivadas ?? '',
      cintura: dto.cintura ?? 0,
      cadera: dto.cadera ?? 0,
      brazo: dto.brazo ?? 0,
      plieguesCutaneos: dto.plieguesCutaneos ?? '',
      porcentajeMusculo: dto.porcentajeMusculo ?? 0,
      autorizacionEstado: dto.autorizacionEstado ?? 'PENDIENTE',
      autorizacionFecha: dto.autorizacionFecha ?? '',
      autorizacionFirma: dto.autorizacionFirma ?? '',
    };

    if (existing) {
      return this.prisma.patient.update({ where: { id: existing.id }, data });
    }

    return this.prisma.patient.create({
      data,
    });
  }

  async listInvitations(nutricionistaId: number) {
    return this.prisma.invitation.findMany({
      where: { nutricionistaId },
      orderBy: { createdAt: 'desc' },
      include: { pacienteUsuario: { select: { nombre: true, correo: true } } },
    });
  }

  async createInvitation(nutricionistaId: number, rawEmail: string) {
    const correo = rawEmail.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { correo } });
    if (user && user.rol !== 'PACIENTE') {
      throw new BadRequestException('El correo pertenece a una cuenta de nutricionista');
    }

    const existingPatient = await this.prisma.patient.findFirst({
      where: { correo, nutricionistaId },
    });
    if (existingPatient) {
      throw new BadRequestException('Este paciente ya pertenece a tu lista');
    }

    const pending = await this.prisma.invitation.findFirst({
      where: { nutricionistaId, correo, estado: InvitationStatus.PENDIENTE },
    });
    if (pending) {
      throw new BadRequestException('Ya existe una invitación pendiente para este correo');
    }

    return this.prisma.invitation.create({
      data: {
        nutricionistaId,
        correo,
        pacienteUsuarioId: user?.id,
      },
      include: { nutricionista: { select: { nombre: true, correo: true } } },
    });
  }

  async updatePatient(id: number, nutricionistaId: number, dto: UpdatePatientDto) {
    await this.getPatient(id, nutricionistaId);
    const updated = await this.prisma.patient.update({
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
        motivoConsulta: dto.motivoConsulta ?? '',
        antecedentesFamiliares: dto.antecedentesFamiliares ?? '',
        historialMedico: dto.historialMedico ?? '',
        medicamentos: dto.medicamentos ?? '',
        habitosAlimenticios: dto.habitosAlimenticios ?? '',
        consumoAgua: dto.consumoAgua ?? '',
        actividadFisica: dto.actividadFisica ?? '',
        objetivos: dto.objetivos ?? '',
        notasPrivadas: dto.notasPrivadas ?? '',
        cintura: dto.cintura ?? 0,
        cadera: dto.cadera ?? 0,
        brazo: dto.brazo ?? 0,
        plieguesCutaneos: dto.plieguesCutaneos ?? '',
        porcentajeMusculo: dto.porcentajeMusculo ?? 0,
        autorizacionEstado: dto.autorizacionEstado ?? 'PENDIENTE',
        autorizacionFecha: dto.autorizacionFecha ?? '',
        autorizacionFirma: dto.autorizacionFirma ?? '',
      },
    });
    await this.prisma.changeLog.create({
      data: {
        nutritionistId: nutricionistaId,
        pacienteId: id,
        entidad: 'Paciente',
        entidadId: id,
        accion: 'ACTUALIZAR',
        descripcion: `Se actualizó la ficha clínica de ${updated.nombre}`,
      },
    });
    return updated;
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
    const tmb = this.calculateTmb(dto.peso, dto.altura * 100, patient.edad, patient.sexo);
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
        cintura: dto.cintura ?? 0,
        cadera: dto.cadera ?? 0,
        brazo: dto.brazo ?? 0,
        plieguesCutaneos: dto.plieguesCutaneos ?? '',
        porcentajeMusculo: dto.porcentajeMusculo ?? 0,
        fecha: dto.fecha,
      },
    });
  }

  async updateEvaluation(
    pacienteId: number,
    evaluationId: number,
    nutricionistaId: number,
    dto: CreateEvaluationDto,
  ) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    const evaluation = await this.prisma.evaluation.findFirst({
      where: { id: evaluationId, pacienteId },
    });
    if (!evaluation) {
      throw new NotFoundException('Evaluación no encontrada');
    }

    const imc = dto.altura > 0 ? dto.peso / (dto.altura * dto.altura) : 0;
    const tmb = this.calculateTmb(dto.peso, dto.altura * 100, patient.edad, patient.sexo);
    const get = tmb * patient.factorActividad;

    const updated = await this.prisma.evaluation.update({
      where: { id: evaluationId },
      data: {
        peso: dto.peso,
        altura: dto.altura,
        grasa: dto.grasa,
        imc,
        tmb,
        get,
        fecha: dto.fecha,
        cintura: dto.cintura ?? 0,
        cadera: dto.cadera ?? 0,
        brazo: dto.brazo ?? 0,
        plieguesCutaneos: dto.plieguesCutaneos ?? '',
        porcentajeMusculo: dto.porcentajeMusculo ?? 0,
      },
    });
    await this.prisma.changeLog.create({
      data: {
        nutritionistId: nutricionistaId,
        pacienteId: pacienteId,
        entidad: 'Evaluación',
        entidadId: evaluationId,
        accion: 'ACTUALIZAR',
        descripcion: 'Se actualizó una evaluación antropométrica',
      },
    });
    return updated;
  }

  async listPlans(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.plan.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createPlan(pacienteId: number, nutricionistaId: number, dto: CreatePlanDto) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    const nutrition = this.completePlanNutrition(patient, dto);
    const plan = await this.prisma.plan.create({
      data: {
        pacienteId,
        titulo: dto.titulo,
        descripcion: dto.descripcion,
        objetivo: dto.objetivo,
        condicion: dto.condicion,
        plantillaNombre: dto.plantillaNombre,
        fechaInicio: dto.fechaInicio,
        fechaFin: dto.fechaFin,
      comidas: dto.comidas ?? '',
      sustituciones: dto.sustituciones ?? '',
      calorias: nutrition.calorias,
      proteinas: nutrition.proteinas,
      carbohidratos: nutrition.carbohidratos,
      grasasMacros: nutrition.grasasMacros,
      periodo: dto.periodo ?? 'Diario',
      recordatorio24h: dto.recordatorio24h ?? '',
      listaCompras: dto.listaCompras ?? '',
      recetas: dto.recetas ?? '',
      distribucionCalorias: dto.distribucionCalorias ?? '',
      aguaRecomendada: nutrition.aguaRecomendada,
      },
    });
    if (patient.usuarioId) {
      await this.createNotification(
        patient.usuarioId,
        'PLAN_ASIGNADO',
        'Nuevo plan alimenticio',
        `Tu nutricionista asignó el plan "${plan.titulo}".`,
      );
    }
    return plan;
  }

  async updatePlan(
    pacienteId: number,
    planId: number,
    nutricionistaId: number,
    dto: CreatePlanDto,
  ) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    const plan = await this.prisma.plan.findFirst({ where: { id: planId, pacienteId } });
    if (!plan) {
      throw new NotFoundException('Plan alimenticio no encontrado');
    }

    const updated = await this.prisma.plan.update({
      where: { id: planId },
      data: {
        titulo: dto.titulo,
        descripcion: dto.descripcion,
        objetivo: dto.objetivo,
        condicion: dto.condicion,
        plantillaNombre: dto.plantillaNombre,
        fechaInicio: dto.fechaInicio,
        fechaFin: dto.fechaFin,
        comidas: dto.comidas ?? '',
        sustituciones: dto.sustituciones ?? '',
        ...this.completePlanNutrition(patient, dto),
        periodo: dto.periodo ?? 'Diario',
        recordatorio24h: dto.recordatorio24h ?? '',
        listaCompras: dto.listaCompras ?? '',
        recetas: dto.recetas ?? '',
        distribucionCalorias: dto.distribucionCalorias ?? '',
        aguaRecomendada: dto.aguaRecomendada ?? 0,
      },
    });
    await this.prisma.changeLog.create({
      data: {
        nutritionistId: nutricionistaId,
        pacienteId: pacienteId,
        entidad: 'Plan',
        entidadId: planId,
        accion: 'ACTUALIZAR',
        descripcion: `Se actualizó el plan ${updated.titulo}`,
      },
    });
    return updated;
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
    const fecha = this.normalizeAppointmentDate(dto.fecha);
    await this.ensureAppointmentSlot(nutricionistaId, fecha);
    const appointment = await this.prisma.appointment.create({
      data: {
        pacienteId,
        fecha,
        motivo: dto.motivo,
        estado: dto.estado as AppointmentStatus,
        canalRecordatorio: dto.canalRecordatorio,
        asistencia: dto.asistencia ?? 'PENDIENTE',
        notas: dto.notas ?? '',
      },
    });
    const patient = await this.prisma.patient.findUnique({
      where: { id: pacienteId },
      select: { usuarioId: true },
    });
    if (patient?.usuarioId) {
      await this.createNotification(
        patient.usuarioId,
        'CITA_CREADA',
        'Nueva cita',
        `Tienes una cita el ${appointment.fecha}.`,
      );
      const appointmentDate = new Date(appointment.fecha.replace(' ', 'T'));
      const reminderDate = new Date(appointmentDate.getTime() - 24 * 60 * 60 * 1000);
      if (!Number.isNaN(reminderDate.getTime()) && reminderDate > new Date()) {
        await this.createNotification(
          patient.usuarioId,
          'RECORDATORIO_CITA',
          'Recordatorio de cita',
          `Recuerda tu cita del ${appointment.fecha}.`,
          reminderDate.toISOString(),
        );
      }
    }
    return appointment;
  }

  async updateAppointment(
    pacienteId: number,
    appointmentId: number,
    nutricionistaId: number,
    dto: CreateAppointmentDto,
  ) {
    await this.getPatient(pacienteId, nutricionistaId);
    const appointment = await this.prisma.appointment.findFirst({
      where: { id: appointmentId, pacienteId },
    });
    if (!appointment) {
      throw new NotFoundException('Cita no encontrada');
    }

    const fecha = this.normalizeAppointmentDate(dto.fecha);
    if (dto.estado !== 'CANCELADA') {
      await this.ensureAppointmentSlot(nutricionistaId, fecha, appointmentId);
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        fecha,
        motivo: dto.motivo,
        estado: dto.estado as AppointmentStatus,
        canalRecordatorio: dto.canalRecordatorio,
        asistencia: dto.asistencia ?? appointment.asistencia,
        notas: dto.notas ?? appointment.notas,
      },
    });
    const patient = await this.prisma.patient.findUnique({
      where: { id: pacienteId },
      select: { usuarioId: true },
    });
    if (patient?.usuarioId) {
      await this.createNotification(
        patient.usuarioId,
        updated.estado === AppointmentStatus.CANCELADA ? 'CITA_CANCELADA' : 'CITA_ACTUALIZADA',
        updated.estado === AppointmentStatus.CANCELADA ? 'Cita cancelada' : 'Cita actualizada',
        `La cita quedó para ${updated.fecha}.`,
        updated.fecha,
      );
    }
    return updated;
  }

  async listMessages(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    await this.prisma.message.updateMany({
      where: { pacienteId, remitente: 'paciente', leido: false },
      data: { leido: true, leidoAt: new Date() },
    });
    return this.prisma.message.findMany({
      where: { pacienteId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createMessage(pacienteId: number, nutricionistaId: number, dto: CreateMessageDto) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    if (dto.remitente === 'nutricionista' && patient.usuarioId) {
      await this.createNotification(
        patient.usuarioId,
        'MENSAJE_NUEVO',
        'Nuevo mensaje',
        'Tu nutricionista te envió un mensaje.',
      );
    }
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

  async updatePayment(
    pacienteId: number,
    paymentId: number,
    nutricionistaId: number,
    dto: CreatePaymentDto,
  ) {
    await this.getPatient(pacienteId, nutricionistaId);
    const payment = await this.prisma.payment.findFirst({ where: { id: paymentId, pacienteId } });
    if (!payment) {
      throw new NotFoundException('Pago no encontrado');
    }

    return this.prisma.payment.update({
      where: { id: paymentId },
      data: {
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

  async createUploadedDocument(
    pacienteId: number,
    nutricionistaId: number,
    file: { filename: string; mimetype: string },
    nombre?: string,
  ) {
    const patient = await this.getPatient(pacienteId, nutricionistaId);
    const document = await this.prisma.document.create({
      data: {
        pacienteId,
        nombre: nombre?.trim() || file.filename,
        tipo: file.mimetype,
        uri: `/uploads/${file.filename}`,
        fecha: new Date().toISOString(),
      },
    });
    if (patient.usuarioId) {
      await this.createNotification(
        patient.usuarioId,
        'DOCUMENTO_NUEVO',
        'Nuevo documento clínico',
        'Tu nutricionista adjuntó un documento a tu ficha.',
      );
    }
    return document;
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

  async listFoods(nutricionistaId: number) {
    return this.prisma.food.findMany({
      where: { OR: [{ nutritionistId: null }, { nutritionistId: nutricionistaId }] },
      orderBy: { nombre: 'asc' },
    });
  }

  async createFood(nutricionistaId: number, dto: CreateFoodDto) {
    return this.prisma.food.create({
      data: {
        nutritionistId: nutricionistaId,
        nombre: dto.nombre.trim(),
        porcion: dto.porcion.trim(),
        calorias: dto.calorias,
        proteinas: dto.proteinas,
        carbohidratos: dto.carbohidratos,
        grasas: dto.grasas,
        fibra: dto.fibra ?? 0,
        sodio: dto.sodio ?? 0,
        azucar: dto.azucar ?? 0,
        micronutrientes: dto.micronutrientes ?? '',
        sustituciones: dto.sustituciones ?? '',
        condiciones: dto.condiciones ?? '',
        favorito: dto.favorito ?? false,
        restringido: dto.restringido ?? false,
      },
    });
  }

  async listTasks(nutricionistaId: number) {
    return this.prisma.nutritionistTask.findMany({
      where: { nutritionistId: nutricionistaId },
      orderBy: [{ completada: 'asc' }, { fechaLimite: 'asc' }],
    });
  }

  private async createNotification(
    userId: number,
    tipo: string,
    titulo: string,
    contenido: string,
    programadaAt?: string,
  ) {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        tipo,
        titulo,
        contenido,
        ...(programadaAt ? { programadaAt: this.parseNotificationDate(programadaAt) } : {}),
      },
    });
    await this.push.sendToUser(userId, titulo, contenido);
    if (!programadaAt) {
      await this.prisma.notification.update({
        where: { id: notification.id },
        data: { enviadaAt: new Date() },
      });
    }
    return notification;
  }

  private completePlanNutrition(patient: { peso: number; altura: number; edad: number; sexo: string; factorActividad: number }, dto: CreatePlanDto) {
    const tmb = patient.peso > 0 && patient.altura > 0
      ? (10 * patient.peso) + (6.25 * patient.altura * 100) - (5 * patient.edad) +
        (patient.sexo.toLowerCase().includes('masc') ? 5 : -161)
      : 0;
    const get = tmb * (patient.factorActividad || 1.2);
    const calories = dto.calorias && dto.calorias > 0 ? dto.calorias : Math.round(get);
    const protein = dto.proteinas && dto.proteinas > 0 ? dto.proteinas : Math.round((calories * 0.3) / 4);
    const carbs = dto.carbohidratos && dto.carbohidratos > 0 ? dto.carbohidratos : Math.round((calories * 0.4) / 4);
    const fats = dto.grasasMacros && dto.grasasMacros > 0 ? dto.grasasMacros : Math.round((calories * 0.3) / 9);
    return {
      calorias: calories,
      proteinas: protein,
      carbohidratos: carbs,
      grasasMacros: fats,
      aguaRecomendada: dto.aguaRecomendada && dto.aguaRecomendada > 0 ? dto.aguaRecomendada : Math.round(patient.peso * 35),
    };
  }

  private parseNotificationDate(value: string) {
    const parsed = new Date(value.replace(' ', 'T'));
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
  }

  async createTask(nutricionistaId: number, dto: CreateTaskDto) {
    return this.prisma.nutritionistTask.create({
      data: {
        nutritionistId: nutricionistaId,
        pacienteId: dto.pacienteId,
        titulo: dto.titulo.trim(),
        descripcion: dto.descripcion ?? '',
        fechaLimite: dto.fechaLimite ?? '',
        completada: dto.completada ?? false,
      },
    });
  }

  async updateTask(nutricionistaId: number, taskId: number, dto: CreateTaskDto) {
    const task = await this.prisma.nutritionistTask.findFirst({
      where: { id: taskId, nutritionistId: nutricionistaId },
    });
    if (!task) throw new NotFoundException('Tarea no encontrada');
    return this.prisma.nutritionistTask.update({
      where: { id: taskId },
      data: {
        ...(dto.titulo ? { titulo: dto.titulo.trim() } : {}),
        ...(dto.descripcion !== undefined ? { descripcion: dto.descripcion } : {}),
        ...(dto.fechaLimite !== undefined ? { fechaLimite: dto.fechaLimite } : {}),
        ...(dto.completada !== undefined ? { completada: dto.completada } : {}),
      },
    });
  }

  async listChangeLogs(nutricionistaId: number) {
    return this.prisma.changeLog.findMany({
      where: { nutritionistId: nutricionistaId },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  async listConsultations(pacienteId: number, nutricionistaId: number) {
    await this.getPatient(pacienteId, nutricionistaId);
    return this.prisma.consultation.findMany({
      where: { pacienteId },
      orderBy: { fecha: 'desc' },
    });
  }

  async createConsultation(
    pacienteId: number,
    nutricionistaId: number,
    dto: CreateConsultationDto,
  ) {
    await this.getPatient(pacienteId, nutricionistaId);
    const consultation = await this.prisma.consultation.create({
      data: {
        pacienteId,
        fecha: dto.fecha,
        motivo: dto.motivo ?? '',
        notas: dto.notas ?? '',
        estado: dto.estado ?? 'REALIZADA',
      },
    });
    await this.prisma.changeLog.create({
      data: {
        nutritionistId: nutricionistaId,
        pacienteId,
        entidad: 'Consulta',
        entidadId: consultation.id,
        accion: 'CREAR',
        descripcion: 'Se registró una consulta clínica',
      },
    });
    return consultation;
  }

  private calculateTmb(peso: number, alturaCm: number, edad: number, sexo: string) {
    const adjustment = sexo.toLowerCase().includes('masc') ? 5 : -161;
    return (10 * peso) + (6.25 * alturaCm) - (5 * edad) + adjustment;
  }

  private async ensureAppointmentSlot(
    nutricionistaId: number,
    fecha: string,
    excludeAppointmentId?: number,
  ) {
    const normalized = this.normalizeAppointmentDate(fecha);
    if (!/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(normalized)) {
      throw new BadRequestException('La cita debe incluir fecha y hora con formato AAAA-MM-DD HH:mm');
    }

    const conflict = await this.prisma.appointment.findFirst({
      where: {
        fecha: normalized,
        estado: { not: AppointmentStatus.CANCELADA },
        patient: { nutricionistaId },
        ...(excludeAppointmentId ? { NOT: { id: excludeAppointmentId } } : {}),
      },
    });

    if (conflict) {
      throw new BadRequestException('Ese horario ya está ocupado por otra cita');
    }
  }

  private normalizeAppointmentDate(fecha: string) {
    return fecha.trim().replace('T', ' ');
  }
}
