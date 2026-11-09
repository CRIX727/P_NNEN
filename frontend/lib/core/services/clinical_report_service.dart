import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';

class ClinicalReportService {
  Future<void> printPatientReport({
    required Paciente patient,
    required List<Evaluacion> evaluations,
    required List<PlanAlimenticio> plans,
  }) async {
    final document = pw.Document();
    final imc = patient.altura > 0
        ? patient.peso / (patient.altura * patient.altura)
        : 0;
    final tmb = (10 * patient.peso) +
        (6.25 * patient.altura * 100) -
        (5 * patient.edad) +
        (patient.sexo.toLowerCase().contains('masc') ? 5 : -161);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(level: 0, text: 'NNEN - Ficha clínica'),
          pw.Text(patient.nombre,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(patient.correo),
          pw.SizedBox(height: 12),
          _section('Datos clínicos', [
            'Motivo de consulta: ${patient.motivoConsulta}',
            'Antecedentes familiares: ${patient.antecedentesFamiliares}',
            'Historial médico: ${patient.historialMedico}',
            'Medicamentos: ${patient.medicamentos}',
            'Hábitos alimenticios: ${patient.habitosAlimenticios}',
            'Consumo de agua: ${patient.consumoAgua}',
            'Actividad física: ${patient.actividadFisica}',
            'Objetivos: ${patient.objetivos}',
            'Alergias: ${patient.alergias}',
            'Enfermedades: ${patient.enfermedades}',
          ]),
          _section('Medidas actuales', [
            'Peso: ${patient.peso.toStringAsFixed(1)} kg',
            'Altura: ${patient.altura.toStringAsFixed(2)} m',
            'IMC: ${imc.toStringAsFixed(1)}',
            'TMB: ${tmb.toStringAsFixed(0)} kcal',
            'GET: ${(tmb * patient.factorActividad).toStringAsFixed(0)} kcal',
            'Grasa corporal: ${patient.grasaCorporal.toStringAsFixed(1)} %',
            'Cintura: ${patient.cintura.toStringAsFixed(1)} cm',
            'Cadera: ${patient.cadera.toStringAsFixed(1)} cm',
            'Brazo: ${patient.brazo.toStringAsFixed(1)} cm',
            'Músculo: ${patient.porcentajeMusculo.toStringAsFixed(1)} %',
          ]),
          pw.Header(level: 1, text: 'Historial de evaluaciones'),
          if (evaluations.isEmpty) pw.Text('No hay evaluaciones registradas.'),
          ...evaluations.map((evaluation) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                    '${evaluation.fecha} - Peso ${evaluation.peso} kg - IMC ${evaluation.imc.toStringAsFixed(1)} - Grasa ${evaluation.grasa}% - Cintura ${evaluation.cintura} cm'),
              )),
          pw.Header(level: 1, text: 'Planes alimenticios'),
          if (plans.isEmpty) pw.Text('No hay planes registrados.'),
          ...plans.map((plan) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(plan.titulo,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${plan.fechaInicio} - ${plan.fechaFin}'),
                      pw.Text(plan.descripcion),
                      if (plan.comidas.isNotEmpty)
                        pw.Text('Comidas: ${plan.comidas}'),
                      pw.Text(
                          'Calorías: ${plan.calorias} | Proteínas: ${plan.proteinas} g | Carbohidratos: ${plan.carbohidratos} g | Grasas: ${plan.grasasMacros} g'),
                    ]),
              )),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  pw.Widget _section(String title, List<String> values) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 1, text: title),
          ...values.map(pw.Text.new),
          pw.SizedBox(height: 10),
        ],
      );
}
