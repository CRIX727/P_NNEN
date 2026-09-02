import { IsDateString, IsIn, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

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
}

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

