import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<{ id?: string }>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const payload = exception instanceof HttpException ? exception.getResponse() : undefined;
    const message =
      typeof payload === 'object' && payload && 'message' in payload
        ? payload.message
        : 'Unexpected server error';

    response.status(status).json({
      success: false,
      error: {
        code: exception instanceof HttpException ? exception.name : 'InternalServerError',
        message,
      },
      meta: {
        requestId: request.id ?? 'untracked',
        timestamp: new Date().toISOString(),
        version: 'v1',
      },
    });
  }
}
