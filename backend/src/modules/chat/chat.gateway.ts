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
};

type ConversationRequest = { pacienteId?: number };
type MessageRequest = { contenido?: string };

@WebSocketGateway({
  namespace: '/chat',
  cors: { origin: true, credentials: true },
})
@Injectable()
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);
  private server!: Server;

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
    } catch (_) {
      client.emit('chat_error', 'Sesión de chat inválida');
      client.disconnect(true);
      return;
    }

    this.logger.debug(`Cliente de chat conectado: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
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
      },
    });
    this.server.to(room).emit('message_received', message);
    return message;
  }

  private canAccessConversation(user: ChatPayload, patient: { correo: string; nutricionistaId: number }) {
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

  private reject(client: Socket, message: string) {
    client.emit('chat_error', message);
    return { success: false, message };
  }
}
