export class AuthUserDto {
  id!: number;
  nombre!: string;
  correo!: string;
  rol!: 'nutricionista' | 'paciente';
}

export class AuthResponseDto {
  success!: boolean;
  accessToken!: string;
  refreshToken!: string;
  usuario!: AuthUserDto;
}

