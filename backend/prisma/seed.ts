import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const nutritionists = [
  { name: 'Dra. Valeria Morales', email: 'nnen.demo.nutri1@gmail.com', password: 'NNENdemo1!' },
  { name: 'Dr. Carlos Mendoza', email: 'nnen.demo.nutri2@gmail.com', password: 'NNENdemo2!' },
];

const patientNames = [
  'Mariana López',
  'José Ramírez',
  'Daniela Torres',
  'Mateo González',
  'Camila Reyes',
  'Luis Martínez',
  'Gabriela Silva',
  'Diego Vargas',
  'Paula Ortega',
  'Sofía Castillo',
];

const goals = ['Bajar peso', 'Masa muscular', 'Clínico', 'Mantenimiento'];
const conditions = ['Sin condición especial', 'Diabetes tipo 2', 'Hipertensión', 'Control renal'];

function metrics(weight: number, height: number, age: number, sex: string, activity: number) {
  const imc = weight / (height * height);
  const tmb = 10 * weight + 6.25 * (height * 100) - 5 * age + (sex === 'Masculino' ? 5 : -161);
  return { imc, tmb, get: tmb * activity };
}

async function main() {
  const passwordHashes = new Map<string, string>();
  for (const nutritionist of nutritionists) {
    passwordHashes.set(nutritionist.password, await bcrypt.hash(nutritionist.password, 10));
  }

  for (let nutritionistIndex = 0; nutritionistIndex < nutritionists.length; nutritionistIndex++) {
    const nutritionistData = nutritionists[nutritionistIndex];
    const nutritionist = await prisma.user.upsert({
      where: { correo: nutritionistData.email },
      update: {
        nombre: nutritionistData.name,
        passwordHash: passwordHashes.get(nutritionistData.password)!,
        rol: UserRole.NUTRICIONISTA,
        precioConsulta: 35 + nutritionistIndex * 10,
        whatsapp: `505888800${nutritionistIndex + 1}`,
      },
      create: {
        nombre: nutritionistData.name,
        correo: nutritionistData.email,
        passwordHash: passwordHashes.get(nutritionistData.password)!,
        rol: UserRole.NUTRICIONISTA,
        precioConsulta: 35 + nutritionistIndex * 10,
        whatsapp: `505888800${nutritionistIndex + 1}`,
      },
    });

    for (let patientIndex = 0; patientIndex < patientNames.length; patientIndex++) {
      const name = patientNames[patientIndex];
      const email = `demo.paciente${nutritionistIndex + 1}.${patientIndex + 1}@nnen.local`;
      const age = 23 + ((nutritionistIndex * 3 + patientIndex) % 25);
      const sex = patientIndex % 2 === 0 ? 'Femenino' : 'Masculino';
      const height = 1.55 + ((patientIndex % 5) * 0.04);
      const weight = 58 + nutritionistIndex * 4 + patientIndex * 1.7;
      const activity = patientIndex % 3 === 0 ? 1.375 : patientIndex % 3 === 1 ? 1.55 : 1.2;

      const patientUser = await prisma.user.upsert({
        where: { correo: email },
        update: {
          nombre: name,
          passwordHash: await bcrypt.hash(`NNENpaciente${nutritionistIndex + 1}${patientIndex + 1}!`, 10),
          rol: UserRole.PACIENTE,
        },
        create: {
          nombre: name,
          correo: email,
          passwordHash: await bcrypt.hash(`NNENpaciente${nutritionistIndex + 1}${patientIndex + 1}!`, 10),
          rol: UserRole.PACIENTE,
        },
      });

      const patient = await prisma.patient.upsert({
        where: { id: (await prisma.patient.findFirst({ where: { correo: email, nutricionistaId: nutritionist.id } }))?.id ?? -1 },
        update: {
          nombre: name,
          peso: weight,
          correo: email,
          usuarioId: patientUser.id,
          nutricionistaId: nutritionist.id,
          altura: height,
          grasaCorporal: 18 + patientIndex * 1.4,
          alergias: patientIndex % 4 === 0 ? 'Lactosa' : '',
          enfermedades: conditions[(nutritionistIndex + patientIndex) % conditions.length] === 'Sin condición especial' ? '' : conditions[(nutritionistIndex + patientIndex) % conditions.length],
          edad: age,
          sexo: sex,
          factorActividad: activity,
          telefono: `505877700${nutritionistIndex}${patientIndex}`,
          notas: 'Seguimiento activo en NNEN.',
          motivoConsulta: 'Mejorar hábitos y alcanzar objetivos nutricionales.',
          antecedentesFamiliares: 'Sin antecedentes relevantes reportados.',
          historialMedico: 'Control nutricional de rutina.',
          medicamentos: patientIndex % 4 === 0 ? 'Según indicación médica' : '',
          habitosAlimenticios: 'Realiza tres comidas y una merienda al día.',
          consumoAgua: '6 vasos diarios',
          actividadFisica: patientIndex % 2 === 0 ? 'Caminata 3 veces por semana' : 'Actividad moderada',
          objetivos: goals[(nutritionistIndex + patientIndex) % goals.length],
          notasPrivadas: 'Revisar adherencia en la próxima consulta.',
          cintura: 72 + patientIndex * 2,
          cadera: 94 + patientIndex * 1.5,
          brazo: 26 + patientIndex * .4,
          plieguesCutaneos: 'Tríceps: 14 mm; subescapular: 16 mm',
          porcentajeMusculo: 34 + patientIndex * .5,
        },
        create: {
          nombre: name,
          correo: email,
          nutricionistaId: nutritionist.id,
          usuarioId: patientUser.id,
          peso: weight,
          altura: height,
          grasaCorporal: 18 + patientIndex * 1.4,
          alergias: patientIndex % 4 === 0 ? 'Lactosa' : '',
          enfermedades: conditions[(nutritionistIndex + patientIndex) % conditions.length] === 'Sin condición especial' ? '' : conditions[(nutritionistIndex + patientIndex) % conditions.length],
          edad: age,
          sexo: sex,
          factorActividad: activity,
          telefono: `505877700${nutritionistIndex}${patientIndex}`,
          notas: 'Seguimiento activo en NNEN.',
          motivoConsulta: 'Mejorar hábitos y alcanzar objetivos nutricionales.',
          antecedentesFamiliares: 'Sin antecedentes relevantes reportados.',
          historialMedico: 'Control nutricional de rutina.',
          medicamentos: patientIndex % 4 === 0 ? 'Según indicación médica' : '',
          habitosAlimenticios: 'Realiza tres comidas y una merienda al día.',
          consumoAgua: '6 vasos diarios',
          actividadFisica: patientIndex % 2 === 0 ? 'Caminata 3 veces por semana' : 'Actividad moderada',
          objetivos: goals[(nutritionistIndex + patientIndex) % goals.length],
          notasPrivadas: 'Revisar adherencia en la próxima consulta.',
          cintura: 72 + patientIndex * 2,
          cadera: 94 + patientIndex * 1.5,
          brazo: 26 + patientIndex * .4,
          plieguesCutaneos: 'Tríceps: 14 mm; subescapular: 16 mm',
          porcentajeMusculo: 34 + patientIndex * .5,
        },
      });

      await prisma.evaluation.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.plan.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.appointment.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.message.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.payment.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.document.deleteMany({ where: { pacienteId: patient.id } });
      await prisma.consultation.deleteMany({ where: { pacienteId: patient.id } });

      const first = metrics(weight + 4, height, age, sex, activity);
      const current = metrics(weight, height, age, sex, activity);
      await prisma.evaluation.createMany({
        data: [
          { pacienteId: patient.id, peso: weight + 4, altura: height, imc: first.imc, tmb: first.tmb, get: first.get, grasa: 20 + patientIndex, cintura: 76 + patientIndex * 2, cadera: 95 + patientIndex * 1.5, brazo: 27 + patientIndex * .4, plieguesCutaneos: 'Tríceps: 16 mm', porcentajeMusculo: 32 + patientIndex * .5, fecha: '2026-07-15' },
          { pacienteId: patient.id, peso: weight + 2, altura: height, imc: metrics(weight + 2, height, age, sex, activity).imc, tmb: first.tmb, get: first.get, grasa: 19 + patientIndex, cintura: 74 + patientIndex * 2, cadera: 95 + patientIndex * 1.5, brazo: 26.5 + patientIndex * .4, plieguesCutaneos: 'Tríceps: 15 mm', porcentajeMusculo: 33 + patientIndex * .5, fecha: '2026-08-15' },
          { pacienteId: patient.id, peso: weight, altura: height, imc: current.imc, tmb: current.tmb, get: current.get, grasa: 18 + patientIndex * 1.4, cintura: 72 + patientIndex * 2, cadera: 94 + patientIndex * 1.5, brazo: 26 + patientIndex * .4, plieguesCutaneos: 'Tríceps: 14 mm', porcentajeMusculo: 34 + patientIndex * .5, fecha: '2026-09-15' },
        ],
      });
      await prisma.plan.createMany({
        data: [
          { pacienteId: patient.id, titulo: 'Plan de seguimiento mensual', descripcion: 'Plan personalizado con desayuno, almuerzo, cena y meriendas.', objetivo: goals[(nutritionistIndex + patientIndex) % goals.length], condicion: conditions[(nutritionistIndex + patientIndex) % conditions.length], plantillaNombre: 'Plantilla seguimiento NNEN', fechaInicio: '2026-09-01', fechaFin: '2026-09-30', periodo: 'Mensual', comidas: 'Desayuno: avena y fruta; Almuerzo: proteína magra, cereal y vegetales; Cena: ensalada y proteína; Merienda: yogur.', sustituciones: 'Pollo por pescado; arroz por papa.', recetas: 'Bowl de pollo y ensalada.', listaCompras: 'Avena, frutas, pollo, vegetales, yogur.', calorias: current.get, proteinas: 110, carbohidratos: 180, grasasMacros: 55, distribucionCalorias: 'Desayuno 25%; almuerzo 35%; cena 25%; meriendas 15%;', aguaRecomendada: weight * .035 },
          { pacienteId: patient.id, titulo: 'Plan de hábitos saludables', descripcion: 'Registrar comidas, caminar 30 minutos y respetar horarios de descanso.', objetivo: 'Mantenimiento', condicion: '', plantillaNombre: 'Plantilla hábitos saludables', fechaInicio: '2026-10-01', fechaFin: '2026-10-31', periodo: 'Mensual', comidas: 'Menú semanal reutilizable.', sustituciones: 'Consultar equivalencias en la base de alimentos.', listaCompras: 'Frutas, vegetales y proteínas.', calorias: current.get, proteinas: 100, carbohidratos: 160, grasasMacros: 50, aguaRecomendada: weight * .035 },
        ],
      });
      await prisma.appointment.createMany({
        data: [
          { pacienteId: patient.id, fecha: '2026-09-28 09:00', motivo: 'Consulta de seguimiento', estado: 'AGENDADA', canalRecordatorio: 'WhatsApp y email' },
          { pacienteId: patient.id, fecha: '2026-08-15 09:00', motivo: 'Evaluación mensual', estado: 'COMPLETADA', canalRecordatorio: 'WhatsApp' },
        ],
      });
      await prisma.message.createMany({
        data: [
          { pacienteId: patient.id, remitente: 'nutricionista', contenido: `Hola ${name}, revisé tu progreso. ¡Vamos muy bien!`, fecha: '2026-09-15 10:00' },
          { pacienteId: patient.id, remitente: 'paciente', contenido: 'Gracias, seguiré el plan y registraré mis comidas.', fecha: '2026-09-15 10:15' },
          { pacienteId: patient.id, remitente: 'nutricionista', contenido: 'Recuerda hidratarte y consultar si aparece alguna molestia.', fecha: '2026-09-16 08:30' },
        ],
      });
      await prisma.payment.createMany({
        data: [
          { pacienteId: patient.id, monto: 40, concepto: 'Consulta de seguimiento', fecha: '2026-09-15', estado: 'PAGADO' },
          { pacienteId: patient.id, monto: 40, concepto: 'Próxima consulta', fecha: '2026-09-28', estado: 'PENDIENTE' },
        ],
      });
      await prisma.document.createMany({
        data: [
          { pacienteId: patient.id, nombre: 'Laboratorio de control', tipo: 'PDF', uri: 'demo://laboratorio-control.pdf', fecha: '2026-08-15' },
          { pacienteId: patient.id, nombre: 'Registro inicial', tipo: 'Imagen', uri: 'demo://registro-inicial.jpg', fecha: '2026-07-15' },
        ],
      });
      await prisma.consultation.createMany({
        data: [
          { pacienteId: patient.id, fecha: '2026-08-15 09:00', motivo: 'Evaluación mensual', notas: 'Se revisaron medidas y adherencia al plan.', estado: 'REALIZADA' },
          { pacienteId: patient.id, fecha: '2026-09-15 09:00', motivo: 'Seguimiento nutricional', notas: 'Se actualizó el plan alimenticio.', estado: 'REALIZADA' },
        ],
      });
    }

    await prisma.food.deleteMany({ where: { nutritionistId: nutritionist.id } });
    await prisma.food.createMany({
      data: [
        { nutritionistId: nutritionist.id, nombre: 'Avena', porcion: '40 g', calorias: 150, proteinas: 5, carbohidratos: 27, grasas: 3, fibra: 4, sodio: 2, azucar: 1, condiciones: 'Hipertensión;Diabetes', sustituciones: 'Quinoa;amaranto' },
        { nutritionistId: nutritionist.id, nombre: 'Pechuga de pollo', porcion: '100 g', calorias: 165, proteinas: 31, carbohidratos: 0, grasas: 3.6, fibra: 0, sodio: 74, azucar: 0, condiciones: 'Diabetes;Hipertensión', sustituciones: 'Pavo;pescado' },
        { nutritionistId: nutritionist.id, nombre: 'Arroz integral', porcion: '1 taza', calorias: 216, proteinas: 5, carbohidratos: 45, grasas: 1.8, fibra: 3.5, sodio: 10, azucar: 0, condiciones: 'Diabetes', sustituciones: 'Papa;quinoa' },
        { nutritionistId: nutritionist.id, nombre: 'Huevo', porcion: '1 unidad', calorias: 78, proteinas: 6, carbohidratos: 1, grasas: 5, fibra: 0, sodio: 62, azucar: 0, condiciones: 'Renal', sustituciones: 'Claras de huevo' },
        { nutritionistId: nutritionist.id, nombre: 'Yogur natural', porcion: '1 taza', calorias: 110, proteinas: 9, carbohidratos: 12, grasas: 3, fibra: 0, sodio: 85, azucar: 9, condiciones: 'Hipertensión', sustituciones: 'Yogur sin azúcar' },
        { nutritionistId: nutritionist.id, nombre: 'Aguacate', porcion: '1/2 unidad', calorias: 160, proteinas: 2, carbohidratos: 9, grasas: 15, fibra: 7, sodio: 7, azucar: 1, condiciones: 'Diabetes', sustituciones: 'Aceite de oliva' },
      ],
    });
    await prisma.nutritionistTask.deleteMany({ where: { nutritionistId: nutritionist.id } });
    await prisma.nutritionistTask.createMany({
      data: [
        { nutritionistId: nutritionist.id, titulo: 'Confirmar citas de mañana', descripcion: 'Enviar recordatorio a pacientes con cita.', fechaLimite: '2026-10-27', completada: false },
        { nutritionistId: nutritionist.id, titulo: 'Revisar pacientes en riesgo', descripcion: 'Verificar condiciones clínicas y progreso.', fechaLimite: '2026-10-28', completada: false },
        { nutritionistId: nutritionist.id, titulo: 'Actualizar plantillas', descripcion: 'Revisar recetas y sustituciones.', fechaLimite: '2026-10-30', completada: true },
      ],
    });
    await prisma.changeLog.create({
      data: {
        nutritionistId: nutritionist.id,
        entidad: 'Demo',
        accion: 'CREAR',
        descripcion: 'Se cargó el escenario demo profesional de NNEN.',
      },
    });
  }

  const templates = [
    { nombre: 'Plantilla pérdida de peso', objetivo: 'Bajar peso', condicion: '', descripcion: 'Porciones controladas, proteína en cada comida y seguimiento semanal.' },
    { nombre: 'Plantilla masa muscular', objetivo: 'Masa muscular', condicion: '', descripcion: 'Aporte proteico distribuido y colaciones planificadas.' },
    { nombre: 'Plantilla control clínico', objetivo: 'Clínico', condicion: 'Diabetes tipo 2', descripcion: 'Plan organizado para controlar horarios y calidad de carbohidratos.' },
  ];
  for (const template of templates) {
    const existing = await prisma.planTemplate.findFirst({ where: { nombre: template.nombre } });
    if (existing) {
      await prisma.planTemplate.update({ where: { id: existing.id }, data: template });
    } else {
      await prisma.planTemplate.create({ data: template });
    }
  }

  console.log('Datos demo de NNEN creados correctamente.');
  console.log('Nutricionistas:', nutritionists.length, '| Pacientes por nutricionista:', patientNames.length);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => prisma.$disconnect());
