enum EnergyFormula { mifflin, harrisBenedict, faoOms, schofield, valencia }

extension EnergyFormulaLabel on EnergyFormula {
  String get label => switch (this) {
        EnergyFormula.mifflin => 'Mifflin-St Jeor',
        EnergyFormula.harrisBenedict => 'Harris-Benedict',
        EnergyFormula.faoOms => 'FAO/OMS',
        EnergyFormula.schofield => 'Schofield',
        EnergyFormula.valencia => 'Valencia',
      };
}

class EnergyInput {
  const EnergyInput({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.activityFactor,
    this.formula = EnergyFormula.mifflin,
  });

  final double weightKg;
  final double heightCm;
  final int age;
  final String sex;
  final double activityFactor;
  final EnergyFormula formula;
}

class EnergyResult {
  const EnergyResult({
    required this.tmb,
    required this.eta,
    required this.get,
    required this.idealWeight,
    required this.healthyMin,
    required this.healthyMax,
    required this.waterLiters,
  });

  final double tmb;
  final double eta;
  final double get;
  final double idealWeight;
  final double healthyMin;
  final double healthyMax;
  final double waterLiters;
}

class NutritionCalculator {
  static EnergyResult calculate(EnergyInput input) {
    final tmb = _basal(input);
    final eta = tmb * .10;
    final get = (tmb + eta) * input.activityFactor;
    final heightM = input.heightCm / 100;
    final heightSquared = heightM * heightM;
    final min = heightSquared * 18.5;
    final max = heightSquared * 24.9;
    return EnergyResult(
      tmb: tmb,
      eta: eta,
      get: get,
      idealWeight: (min + max) / 2,
      healthyMin: min,
      healthyMax: max,
      waterLiters: input.weightKg * .035,
    );
  }

  static double _basal(EnergyInput input) {
    final male = input.sex.toLowerCase().contains('masc');
    final w = input.weightKg;
    final h = input.heightCm;
    final a = input.age;
    return switch (input.formula) {
      EnergyFormula.mifflin => 10 * w + 6.25 * h - 5 * a + (male ? 5 : -161),
      EnergyFormula.harrisBenedict => male
          ? 13.397 * w + 4.799 * h - 5.677 * a + 88.362
          : 9.247 * w + 3.098 * h - 4.330 * a + 447.593,
      EnergyFormula.faoOms => male ? _faoMale(w, a) : _faoFemale(w, a),
      EnergyFormula.schofield =>
        male ? _schofieldMale(w, a) : _schofieldFemale(w, a),
      EnergyFormula.valencia => male ? 13.5 * w + 487 : 10.5 * w + 596,
    };
  }

  static double _faoMale(double w, int a) => a < 30
      ? 15.3 * w + 679
      : a < 60
          ? 11.6 * w + 879
          : 13.5 * w + 487;

  static double _faoFemale(double w, int a) => a < 30
      ? 14.7 * w + 496
      : a < 60
          ? 8.7 * w + 829
          : 10.5 * w + 596;

  static double _schofieldMale(double w, int a) => a < 30
      ? 15.057 * w + 692.2
      : a < 60
          ? 11.472 * w + 873.1
          : 11.711 * w + 587.7;

  static double _schofieldFemale(double w, int a) => a < 30
      ? 14.818 * w + 486.6
      : a < 60
          ? 8.126 * w + 845.6
          : 9.082 * w + 658.5;

  static double bmi(double weightKg, double heightM) =>
      heightM <= 0 ? 0 : weightKg / (heightM * heightM);

  static double waistHipRatio(double waistCm, double hipCm) =>
      hipCm <= 0 ? 0 : waistCm / hipCm;

  static double armMuscleArea(double armCm, double skinfoldMm) {
    final correctedArm = armCm - (3.1416 * (skinfoldMm / 10));
    return correctedArm <= 0 ? 0 : (correctedArm * correctedArm) / (4 * 3.1416);
  }

  static double adequacy(double actual, double target) =>
      target <= 0 ? 0 : actual / target * 100;

  static Map<String, double> macroPercentages({
    required double protein,
    required double carbohydrates,
    required double fat,
  }) {
    final proteinKcal = protein * 4;
    final carbsKcal = carbohydrates * 4;
    final fatKcal = fat * 9;
    final total = proteinKcal + carbsKcal + fatKcal;
    if (total <= 0) return {'Proteínas': 0, 'Carbohidratos': 0, 'Grasas': 0};
    return {
      'Proteínas': proteinKcal / total * 100,
      'Carbohidratos': carbsKcal / total * 100,
      'Grasas': fatKcal / total * 100,
    };
  }

  static double convertToGrams(double amount, String unit) => switch (unit) {
        'unidad' => amount * 50,
        'taza' => amount * 240,
        'cucharada' => amount * 15,
        _ => amount,
      };
}
