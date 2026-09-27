import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreatePatientMessageDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  contenido!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  fecha?: string;
}
