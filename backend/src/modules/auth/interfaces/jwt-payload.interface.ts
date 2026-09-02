export interface JwtPayload {
  sub: number;
  correo: string;
  rol: 'nutricionista' | 'paciente';
  nombre: string;
}

