import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/nutricionista_summary.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';

class PatientDto {
  const PatientDto({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.nutricionistaId,
    required this.peso,
    required this.altura,
    required this.grasaCorporal,
    required this.alergias,
    required this.enfermedades,
    required this.edad,
    required this.sexo,
    required this.factorActividad,
    required this.telefono,
    required this.notas,
  });

  factory PatientDto.fromJson(Map<String, dynamic> json) {
    return PatientDto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      nutricionistaId: (json['nutricionistaId'] as num?)?.toInt() ?? 0,
      peso: (json['peso'] as num?)?.toDouble() ?? 0,
      altura: (json['altura'] as num?)?.toDouble() ?? 0,
      grasaCorporal: (json['grasaCorporal'] as num?)?.toDouble() ?? 0,
      alergias: json['alergias'] as String? ?? '',
      enfermedades: json['enfermedades'] as String? ?? '',
      edad: (json['edad'] as num?)?.toInt() ?? 30,
      sexo: json['sexo'] as String? ?? 'Femenino',
      factorActividad: (json['factorActividad'] as num?)?.toDouble() ?? 1.2,
      telefono: json['telefono'] as String? ?? '',
      notas: json['notas'] as String? ?? '',
    );
  }

  final int id;
  final String nombre;
  final String correo;
  final int nutricionistaId;
  final double peso;
  final double altura;
  final double grasaCorporal;
  final String alergias;
  final String enfermedades;
  final int edad;
  final String sexo;
  final double factorActividad;
  final String telefono;
  final String notas;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'peso': peso,
        'altura': altura,
        'grasaCorporal': grasaCorporal,
        'alergias': alergias,
        'enfermedades': enfermedades,
        'edad': edad,
        'sexo': sexo,
        'factorActividad': factorActividad,
        'telefono': telefono,
        'notas': notas,
      };

  Paciente toEntity() {
    return Paciente(
      id: id,
      nombre: nombre,
      correo: correo,
      nutricionistaId: nutricionistaId,
      peso: peso,
      altura: altura,
      grasaCorporal: grasaCorporal,
      alergias: alergias,
      enfermedades: enfermedades,
      edad: edad,
      sexo: sexo,
      factorActividad: factorActividad,
      telefono: telefono,
      notas: notas,
    );
  }
}

class EvaluationDto {
  const EvaluationDto({
    required this.id,
    required this.pacienteId,
    required this.peso,
    required this.altura,
    required this.imc,
    required this.tmb,
    required this.get,
    required this.grasa,
    required this.fecha,
  });

  factory EvaluationDto.fromJson(Map<String, dynamic> json) {
    return EvaluationDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      peso: (json['peso'] as num).toDouble(),
      altura: (json['altura'] as num).toDouble(),
      imc: (json['imc'] as num).toDouble(),
      tmb: (json['tmb'] as num?)?.toDouble() ?? 0,
      get: (json['get'] as num?)?.toDouble() ?? 0,
      grasa: (json['grasa'] as num).toDouble(),
      fecha: json['fecha'] as String? ?? '',
    );
  }

  final int id;
  final int pacienteId;
  final double peso;
  final double altura;
  final double imc;
  final double tmb;
  final double get;
  final double grasa;
  final String fecha;

  Map<String, dynamic> toJson() => {
        'peso': peso,
        'altura': altura,
        'grasa': grasa,
        'fecha': fecha,
      };

  Evaluacion toEntity() {
    return Evaluacion(
      id: id,
      pacienteId: pacienteId,
      peso: peso,
      altura: altura,
      imc: imc,
      tmb: tmb,
      get: get,
      grasa: grasa,
      fecha: fecha,
    );
  }
}

class PlanDto {
  const PlanDto({
    required this.id,
    required this.pacienteId,
    required this.titulo,
    required this.descripcion,
    required this.objetivo,
    required this.condicion,
    required this.plantillaNombre,
    required this.fechaInicio,
    required this.fechaFin,
  });

  factory PlanDto.fromJson(Map<String, dynamic> json) {
    return PlanDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      objetivo: json['objetivo'] as String? ?? '',
      condicion: json['condicion'] as String? ?? '',
      plantillaNombre: json['plantillaNombre'] as String? ?? '',
      fechaInicio: json['fechaInicio'] as String? ?? '',
      fechaFin: json['fechaFin'] as String? ?? '',
    );
  }

  final int id;
  final int pacienteId;
  final String titulo;
  final String descripcion;
  final String objetivo;
  final String condicion;
  final String plantillaNombre;
  final String fechaInicio;
  final String fechaFin;

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'objetivo': objetivo,
        'condicion': condicion,
        'plantillaNombre': plantillaNombre,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      };

  PlanAlimenticio toEntity() {
    return PlanAlimenticio(
      id: id,
      pacienteId: pacienteId,
      titulo: titulo,
      descripcion: descripcion,
      objetivo: objetivo,
      condicion: condicion,
      plantillaNombre: plantillaNombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}

class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    required this.motivo,
    required this.estado,
    required this.canalRecordatorio,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      fecha: json['fecha'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      estado: _appointmentStateFromString(json['estado'] as String? ?? 'AGENDADA'),
      canalRecordatorio: json['canalRecordatorio'] as String? ?? '',
    );
  }

  final int id;
  final int pacienteId;
  final String fecha;
  final String motivo;
  final CitaEstado estado;
  final String canalRecordatorio;

  Map<String, dynamic> toJson() => {
        'fecha': fecha,
        'motivo': motivo,
        'estado': _appointmentStateToApi(estado),
        'canalRecordatorio': canalRecordatorio,
      };

  CitaPaciente toEntity() {
    return CitaPaciente(
      id: id,
      pacienteId: pacienteId,
      fecha: fecha,
      motivo: motivo,
      estado: estado,
      canalRecordatorio: canalRecordatorio,
    );
  }
}

class MessageDto {
  const MessageDto({
    required this.id,
    required this.pacienteId,
    required this.remitente,
    required this.contenido,
    required this.fecha,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      remitente: json['remitente'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
    );
  }

  final int id;
  final int pacienteId;
  final String remitente;
  final String contenido;
  final String fecha;

  Map<String, dynamic> toJson() => {
        'remitente': remitente,
        'contenido': contenido,
        'fecha': fecha,
      };

  MensajePaciente toEntity() {
    return MensajePaciente(
      id: id,
      pacienteId: pacienteId,
      remitente: remitente,
      contenido: contenido,
      fecha: fecha,
    );
  }
}

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.pacienteId,
    required this.monto,
    required this.concepto,
    required this.fecha,
    required this.estado,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      monto: (json['monto'] as num).toDouble(),
      concepto: json['concepto'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      estado: _paymentStateFromString(json['estado'] as String? ?? 'PENDIENTE'),
    );
  }

  final int id;
  final int pacienteId;
  final double monto;
  final String concepto;
  final String fecha;
  final PagoEstado estado;

  Map<String, dynamic> toJson() => {
        'monto': monto,
        'concepto': concepto,
        'fecha': fecha,
        'estado': _paymentStateToApi(estado),
      };

  PagoPaciente toEntity() {
    return PagoPaciente(
      id: id,
      pacienteId: pacienteId,
      monto: monto,
      concepto: concepto,
      fecha: fecha,
      estado: estado,
    );
  }
}

class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.pacienteId,
    required this.nombre,
    required this.tipo,
    required this.uri,
    required this.fecha,
  });

  factory DocumentDto.fromJson(Map<String, dynamic> json) {
    return DocumentDto(
      id: (json['id'] as num).toInt(),
      pacienteId: (json['pacienteId'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      uri: json['uri'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
    );
  }

  final int id;
  final int pacienteId;
  final String nombre;
  final String tipo;
  final String uri;
  final String fecha;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'tipo': tipo,
        'uri': uri,
        'fecha': fecha,
      };

  DocumentoPaciente toEntity() {
    return DocumentoPaciente(
      id: id,
      pacienteId: pacienteId,
      nombre: nombre,
      tipo: tipo,
      uri: uri,
      fecha: fecha,
    );
  }
}

class TemplateDto {
  const TemplateDto({
    required this.id,
    required this.nombre,
    required this.objetivo,
    required this.condicion,
    required this.descripcion,
  });

  factory TemplateDto.fromJson(Map<String, dynamic> json) {
    return TemplateDto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      objetivo: json['objetivo'] as String? ?? '',
      condicion: json['condicion'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }

  final int id;
  final String nombre;
  final String objetivo;
  final String condicion;
  final String descripcion;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'objetivo': objetivo,
        'condicion': condicion,
        'descripcion': descripcion,
      };

  PlantillaPlan toEntity() {
    return PlantillaPlan(
      id: id,
      nombre: nombre,
      objetivo: objetivo,
      condicion: condicion,
      descripcion: descripcion,
    );
  }
}

class DashboardDto {
  const DashboardDto({
    required this.totalPacientes,
    required this.totalEvaluaciones,
    required this.totalPlanes,
    required this.totalCitas,
    required this.totalMensajes,
    required this.pagosPendientes,
    required this.imcPromedio,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      totalPacientes: (json['totalPacientes'] as num?)?.toInt() ?? 0,
      totalEvaluaciones: (json['totalEvaluaciones'] as num?)?.toInt() ?? 0,
      totalPlanes: (json['totalPlanes'] as num?)?.toInt() ?? 0,
      totalCitas: (json['totalCitas'] as num?)?.toInt() ?? 0,
      totalMensajes: (json['totalMensajes'] as num?)?.toInt() ?? 0,
      pagosPendientes: (json['pagosPendientes'] as num?)?.toInt() ?? 0,
      imcPromedio: (json['imcPromedio'] as num?)?.toDouble() ?? 0,
    );
  }

  final int totalPacientes;
  final int totalEvaluaciones;
  final int totalPlanes;
  final int totalCitas;
  final int totalMensajes;
  final int pagosPendientes;
  final double imcPromedio;

  NutricionistaSummary toEntity() {
    return NutricionistaSummary(
      totalPacientes: totalPacientes,
      totalEvaluaciones: totalEvaluaciones,
      totalPlanes: totalPlanes,
      totalCitas: totalCitas,
      totalMensajes: totalMensajes,
      pagosPendientes: pagosPendientes,
      imcPromedio: imcPromedio,
    );
  }
}

class SettingsDto {
  const SettingsDto({
    required this.precioConsulta,
    required this.whatsapp,
  });

  factory SettingsDto.fromJson(Map<String, dynamic> json) {
    return SettingsDto(
      precioConsulta: (json['precioConsulta'] as num?)?.toDouble() ?? 0,
      whatsapp: json['whatsapp'] as String? ?? '',
    );
  }

  final double precioConsulta;
  final String whatsapp;

  Map<String, dynamic> toJson() => {
        'precioConsulta': precioConsulta,
        'whatsapp': whatsapp,
      };

  NutricionistaSettings toEntity() {
    return NutricionistaSettings(
      precioConsulta: precioConsulta,
      whatsapp: whatsapp,
    );
  }
}

String _appointmentStateToApi(CitaEstado estado) {
  return switch (estado) {
    CitaEstado.agendada => 'AGENDADA',
    CitaEstado.reprogramada => 'REPROGRAMADA',
    CitaEstado.completada => 'COMPLETADA',
    CitaEstado.cancelada => 'CANCELADA',
  };
}

CitaEstado _appointmentStateFromString(String value) {
  return switch (value.toUpperCase()) {
    'REPROGRAMADA' => CitaEstado.reprogramada,
    'COMPLETADA' => CitaEstado.completada,
    'CANCELADA' => CitaEstado.cancelada,
    _ => CitaEstado.agendada,
  };
}

String _paymentStateToApi(PagoEstado estado) {
  return switch (estado) {
    PagoEstado.pendiente => 'PENDIENTE',
    PagoEstado.pagado => 'PAGADO',
  };
}

PagoEstado _paymentStateFromString(String value) {
  return value.toUpperCase() == 'PAGADO'
      ? PagoEstado.pagado
      : PagoEstado.pendiente;
}

