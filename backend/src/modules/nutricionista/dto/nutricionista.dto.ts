import { IsDateString, IsEmail, IsIn, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class CreatePatientDto {
  @IsString()
  nombre!: string;

  @IsString()
  correo!: string;

  @IsNumber()
  peso!: number;

  @IsNumber()
  altura!: number;

  @IsNumber()
  grasaCorporal!: number;

  @IsString()
  alergias!: string;

  @IsString()
  enfermedades!: string;

  @IsNumber()
  edad!: number;

  @IsString()
  sexo!: string;

  @IsNumber()
  factorActividad!: number;

  @IsString()
  telefono!: string;

  @IsString()
  notas!: string;

  @IsOptional() @IsString() motivoConsulta?: string;
  @IsOptional() @IsString() antecedentesFamiliares?: string;
  @IsOptional() @IsString() historialMedico?: string;
  @IsOptional() @IsString() medicamentos?: string;
  @IsOptional() @IsString() habitosAlimenticios?: string;
  @IsOptional() @IsString() consumoAgua?: string;
  @IsOptional() @IsString() actividadFisica?: string;
  @IsOptional() @IsString() objetivos?: string;
  @IsOptional() @IsString() notasPrivadas?: string;
  @IsOptional() @IsNumber() cintura?: number;
  @IsOptional() @IsNumber() cadera?: number;
  @IsOptional() @IsNumber() brazo?: number;
  @IsOptional() @IsString() plieguesCutaneos?: string;
  @IsOptional() @IsNumber() porcentajeMusculo?: number;
  @IsOptional() @IsString() autorizacionEstado?: string;
  @IsOptional() @IsString() autorizacionFecha?: string;
  @IsOptional() @IsString() autorizacionFirma?: string;
}

export class UpdatePatientDto extends CreatePatientDto {}

export class CreateEvaluationDto {
  @IsNumber()
  peso!: number;

  @IsNumber()
  altura!: number;

  @IsNumber()
  grasa!: number;

  @IsString()
  fecha!: string;

  @IsOptional() @IsNumber() cintura?: number;
  @IsOptional() @IsNumber() cadera?: number;
  @IsOptional() @IsNumber() brazo?: number;
  @IsOptional() @IsString() plieguesCutaneos?: string;
  @IsOptional() @IsNumber() porcentajeMusculo?: number;
}

export class UpdateEvaluationDto extends CreateEvaluationDto {}

export class CreatePlanDto {
  @IsString()
  titulo!: string;

  @IsString()
  descripcion!: string;

  @IsString()
  objetivo!: string;

  @IsString()
  condicion!: string;

  @IsString()
  plantillaNombre!: string;

  @IsString()
  fechaInicio!: string;

  @IsString()
  fechaFin!: string;

  @IsOptional() @IsString() comidas?: string;
  @IsOptional() @IsString() sustituciones?: string;
  @IsOptional() @IsNumber() calorias?: number;
  @IsOptional() @IsNumber() proteinas?: number;
  @IsOptional() @IsNumber() carbohidratos?: number;
  @IsOptional() @IsNumber() grasasMacros?: number;
  @IsOptional() @IsString() periodo?: string;
  @IsOptional() @IsString() recordatorio24h?: string;
  @IsOptional() @IsString() listaCompras?: string;
  @IsOptional() @IsString() recetas?: string;
  @IsOptional() @IsString() distribucionCalorias?: string;
  @IsOptional() @IsNumber() aguaRecomendada?: number;
}

export class CreateAppointmentDto {
  @IsString()
  fecha!: string;

  @IsString()
  motivo!: string;

  @IsIn(['AGENDADA', 'REPROGRAMADA', 'COMPLETADA', 'CANCELADA'])
  estado!: 'AGENDADA' | 'REPROGRAMADA' | 'COMPLETADA' | 'CANCELADA';

  @IsString()
  canalRecordatorio!: string;

  @IsOptional() @IsString() asistencia?: string;
  @IsOptional() @IsString() notas?: string;
}

export class CreateMessageDto {
  @IsString()
  remitente!: string;

  @IsString()
  contenido!: string;

  @IsString()
  fecha!: string;
}

export class CreatePaymentDto {
  @IsNumber()
  monto!: number;

  @IsString()
  concepto!: string;

  @IsString()
  fecha!: string;

  @IsIn(['PENDIENTE', 'PAGADO'])
  estado!: 'PENDIENTE' | 'PAGADO';
}

export class CreateDocumentDto {
  @IsString()
  nombre!: string;

  @IsString()
  tipo!: string;

  @IsString()
  uri!: string;

  @IsString()
  fecha!: string;
}

export class CreateTemplateDto {
  @IsString()
  nombre!: string;

  @IsString()
  objetivo!: string;

  @IsString()
  condicion!: string;

  @IsString()
  descripcion!: string;
}

export class UpdateSettingsDto {
  @IsOptional()
  @IsNumber()
  precioConsulta?: number;

  @IsOptional()
  @IsString()
  whatsapp?: string;
}

export class CreateInvitationDto {
  @IsEmail({}, { message: 'El correo del paciente no es válido' })
  correo!: string;
}

export class CreateFoodDto {
  @IsString() nombre!: string;
  @IsString() porcion!: string;
  @IsNumber() calorias!: number;
  @IsNumber() proteinas!: number;
  @IsNumber() carbohidratos!: number;
  @IsNumber() grasas!: number;
  @IsOptional() @IsNumber() fibra?: number;
  @IsOptional() @IsNumber() sodio?: number;
  @IsOptional() @IsNumber() azucar?: number;
  @IsOptional() @IsString() micronutrientes?: string;
  @IsOptional() @IsString() sustituciones?: string;
  @IsOptional() @IsString() condiciones?: string;
  @IsOptional() favorito?: boolean;
  @IsOptional() restringido?: boolean;
}

export class CreateTaskDto {
  @IsString() titulo!: string;
  @IsOptional() @IsString() descripcion?: string;
  @IsOptional() @IsString() fechaLimite?: string;
  @IsOptional() @IsNumber() pacienteId?: number;
  @IsOptional() completada?: boolean;
}

export class CreateConsultationDto {
  @IsString() fecha!: string;
  @IsOptional() @IsString() motivo?: string;
  @IsOptional() @IsString() notas?: string;
  @IsOptional() @IsString() estado?: string;
}

