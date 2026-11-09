import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AppointmentStatus, UserRole } from '@prisma/client';
import { NutricionistaService } from './nutricionista.service';

describe('NutricionistaService', () => {
  const prisma = {
    patient: { findFirst: jest.fn(), update: jest.fn() },
    evaluation: { create: jest.fn(), findMany: jest.fn() },
    appointment: { findFirst: jest.fn(), create: jest.fn() },
  } as any;
  const push = { sendToUser: jest.fn() } as any;
  let service: NutricionistaService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NutricionistaService(prisma, push);
  });

  it('rechaza el acceso a un paciente que no pertenece al nutricionista', async () => {
    prisma.patient.findFirst.mockResolvedValue(null);
    await expect(service.getPatient(10, 20)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('calcula IMC, TMB y GET al registrar una evaluación', async () => {
    prisma.patient.findFirst.mockResolvedValue({
      id: 10,
      altura: 1.75,
      edad: 30,
      sexo: 'masculino',
      factorActividad: 1.2,
    });
    prisma.patient.update.mockResolvedValue({});
    prisma.evaluation.create.mockImplementation(async ({ data }: any) => data);

    const result = await service.createEvaluation(10, 20, {
      peso: 70,
      altura: 1.75,
      grasa: 20,
      fecha: '2026-10-12',
    } as any);

    expect(result.imc).toBeCloseTo(22.857, 2);
    expect(result.tmb).toBeCloseTo(1648.75, 2);
    expect(result.get).toBeCloseTo(1978.5, 2);
  });

  it('rechaza una cita con horario ocupado', async () => {
    prisma.patient.findFirst.mockResolvedValue({ id: 10 });
    prisma.appointment.findFirst.mockResolvedValue({ id: 99, estado: AppointmentStatus.AGENDADA });

    await expect(service.createAppointment(10, 20, {
      fecha: '2026-10-20 10:00',
      motivo: 'Control',
      estado: 'AGENDADA',
      canalRecordatorio: 'APP',
    } as any)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rechaza una fecha de cita con formato inválido', async () => {
    prisma.patient.findFirst.mockResolvedValue({ id: 10 });
    await expect(service.createAppointment(10, 20, {
      fecha: '20/10/2026 10:00',
      motivo: 'Control',
      estado: 'AGENDADA',
      canalRecordatorio: 'APP',
    } as any)).rejects.toBeInstanceOf(BadRequestException);
  });
});
