export interface JwtPayload {
  sub: number;
  sid?: string;
  correo: string;
  rol: 'nutricionista' | 'paciente';
  nombre: string;
}

