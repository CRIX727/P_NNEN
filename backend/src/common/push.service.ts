import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

import { PrismaService } from './prisma.service';

@Injectable()
export class PushService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PushService.name);
  private enabled = false;
  private scheduler?: NodeJS.Timeout;

  constructor(private readonly prisma: PrismaService) {
    if (process.env.FIREBASE_PROJECT_ID && process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      if (getApps().length === 0) {
        initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID, credential: applicationDefault() });
      }
      this.enabled = true;
    }
  }

  onModuleInit() {
    this.scheduler = setInterval(() => {
      this.dispatchScheduledNotifications().catch((error) =>
        this.logger.warn(`No se pudieron procesar recordatorios: ${String(error)}`),
      );
    }, 60_000);
  }

  onModuleDestroy() {
    if (this.scheduler) clearInterval(this.scheduler);
  }

  async registerToken(userId: number, token: string, plataforma = 'android') {
    return this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, plataforma },
      update: { userId, plataforma },
    });
  }

  async removeToken(userId: number, token: string) {
    await this.prisma.deviceToken.deleteMany({ where: { userId, token } });
  }

  async sendToUser(userId: number, title: string, body: string) {
    if (!this.enabled) return;
    const tokens = await this.prisma.deviceToken.findMany({ where: { userId } });
    if (tokens.length === 0) return;
    try {
      const result = await getMessaging().sendEachForMulticast({
        tokens: tokens.map((item) => item.token),
        notification: { title, body },
        data: { source: 'nnen' },
      });
      const invalidTokens = tokens
        .filter((_item, index) => !result.responses[index]?.success)
        .map((item) => item.token);
      if (invalidTokens.length > 0) {
        await this.prisma.deviceToken.deleteMany({ where: { token: { in: invalidTokens } } });
      }
    } catch (error) {
      this.logger.warn(`No se pudo enviar push FCM: ${String(error)}`);
    }
  }

  async dispatchScheduledNotifications() {
    const due = await this.prisma.notification.findMany({
      where: { enviadaAt: null, programadaAt: { lte: new Date() } },
      orderBy: { programadaAt: 'asc' },
      take: 100,
    });
    for (const notification of due) {
      await this.sendToUser(notification.userId, notification.titulo, notification.contenido);
      await this.prisma.notification.update({
        where: { id: notification.id },
        data: { enviadaAt: new Date() },
      });
    }
  }
}
