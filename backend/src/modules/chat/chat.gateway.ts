import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

import { PrismaService } from '../../common/prisma.service';

type ChatPayload = {
  sub: number;
  correo: string;
  rol: 'nutricionista' | 'paciente';
  sid?: string;
};

type ConversationRequest = { pacienteId?: number };
type MessageRequest = { contenido?: string };

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: (process.env.FRONTEND_ORIGIN ?? 'http://localhost:3000')
      .split(',')
      .map((origin) => origin.trim()),
    credentials: true,
  },
})
@Injectable()
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);
  private server!: Server;
  private readonly onlineUsers = new Map<number, number>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  afterInit(server: Server) {
    this.server = server;
  }

  async handleConnection(client: Socket) {
    try {
      const token = this.readToken(client);
      const payload = this.jwtService.verify<ChatPayload>(token, {
        secret: this.configService.get<string>('JWT_ACCESS_SECRET') ?? 'change-me-access-secret',
      });
      client.data.user = payload;
      this.onlineUsers.set(payload.sub, (this.onlineUsers.get(payload.sub) ?? 0) + 1);
      client.emit('presence_status', { userId: payload.sub, online: true });
    } catch (_) {
      client.emit('chat_error', 'Sesión de chat inválida');
      client.disconnect(true);
      return;
    }

    this.logger.debug(`Cliente de chat conectado: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    const user = client.data.user as ChatPayload | undefined;
    if (user) {
      const remaining = (this.onlineUsers.get(user.sub) ?? 1) - 1;
      if (remaining <= 0) this.onlineUsers.delete(user.sub);
      else this.onlineUsers.set(user.sub, remaining);
      const room = client.data.room as string | undefined;
      if (room) this.server.to(room).emit('presence_status', {
        userId: user.sub,
        online: remaining > 0,
      });
    }
    this.logger.debug(`Cliente de chat desconectado: ${client.id}`);
  }

  @SubscribeMessage('join_conversation')
  async joinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() request: ConversationRequest,
  ) {
    const patientId = Number(request?.pacienteId);
    if (!Number.isInteger(patientId) || patientId <= 0) {
      return this.reject(client, 'Conversación inválida');
    }

    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { id: true, correo: true, nutricionistaId: true },
    });
    const user = client.data.user as ChatPayload | undefined;
    if (!patient || !user || !this.canAccessConversation(user, patient)) {
      return this.reject(client, 'No tienes acceso a esta conversación');
    }

    const room = this.roomName(patientId);
    client.data.room = room;
    await client.join(room);
    client.emit('conversation_joined', { pacienteId: patientId });
    const otherUserId = user.rol === 'paciente'
      ? patient.nutricionistaId
      : await this.findPatientUserId(patientId);
    client.emit('presence_status', {
      userId: otherUserId,
      online: otherUserId ? this.onlineUsers.has(otherUserId) : false,
    });
  }

  @SubscribeMessage('send_message')
  async sendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() request: MessageRequest,
  ) {
    const content = request?.contenido?.trim();
    const room = client.data.room as string | undefined;
    const user = client.data.user as ChatPayload | undefined;
    if (!content || !room || !user) {
      return this.reject(client, 'No se pudo enviar el mensaje');
    }

    const pacienteId = Number(room.replace('patient:', ''));
    const patient = await this.prisma.patient.findUnique({
      where: { id: pacienteId },
      select: { id: true, correo: true, nutricionistaId: true },
    });
    if (!patient || !this.canAccessConversation(user, patient)) {
      return this.reject(client, 'No tienes acceso a esta conversación');
    }

    const message = await this.prisma.message.create({
      data: {
        pacienteId,
        remitente: user.rol,
        contenido: content,
        fecha: new Date().toISOString(),
        leido: false,
        entregado: true,
        entregadoAt: new Date(),
      },
    });
    this.server.to(room).emit('message_received', message);
    this.server.to(room).emit('message_status', {
      messageId: message.id,
      status: 'delivered',
    });
    return message;
  }

  @SubscribeMessage('mark_read')
  async markRead(@ConnectedSocket() client: Socket, @MessageBody() request: { messageId?: number }) {
    const messageId = Number(request?.messageId);
    const room = client.data.room as string | undefined;
    const user = client.data.user as ChatPayload | undefined;
    if (!Number.isInteger(messageId) || !room || !user) return this.reject(client, 'Mensaje inválido');
    const pacienteId = Number(room.replace('patient:', ''));
    const patient = await this.prisma.patient.findUnique({
      where: { id: pacienteId },
      select: { id: true, correo: true, nutricionistaId: true },
    });
    if (!patient || !this.canAccessConversation(user, patient)) {
      return this.reject(client, 'No tienes acceso a esta conversación');
    }
    await this.prisma.message.updateMany({
      where: { id: messageId, pacienteId, remitente: { not: user.rol } },
      data: { leido: true, leidoAt: new Date() },
    });
    this.server.to(room).emit('message_status', { messageId, status: 'read' });
  }

  private canAccessConversation(user: ChatPayload, patient: { correo: string; nutricionistaId: number | null }) {
    return user.rol === 'paciente'
      ? patient.correo.toLowerCase() === user.correo.toLowerCase()
      : patient.nutricionistaId === user.sub;
  }

  private readToken(client: Socket) {
    const authToken = client.handshake.auth?.token;
    const header = client.handshake.headers.authorization;
    const token = typeof authToken === 'string' ? authToken : header?.replace('Bearer ', '');
    if (!token) throw new Error('Token requerido');
    return token;
  }

  private roomName(patientId: number) {
    return `patient:${patientId}`;
  }

  private async findPatientUserId(patientId: number) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { usuarioId: true },
    });
    return patient?.usuarioId ?? null;
  }

  private reject(client: Socket, message: string) {
    client.emit('chat_error', message);
    return { success: false, message };
  }
}
