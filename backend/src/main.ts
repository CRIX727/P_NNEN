import { BadRequestException, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: process.env.FRONTEND_ORIGIN ?? true,
    credentials: true,
  });

  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      exceptionFactory: (errors) => {
        const firstConstraint =
          errors
            .flatMap((error) => Object.values(error.constraints ?? {}))
            .find((message) => Boolean(message)) ?? 'Datos inválidos';
        return new BadRequestException(firstConstraint);
      },
    }),
  );

  await app.listen(process.env.PORT ?? 3000);
}

bootstrap();
