import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { map, Observable } from 'rxjs';

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T> {
  intercept(context: ExecutionContext, next: CallHandler<T>): Observable<unknown> {
    const request = context.switchToHttp().getRequest<{ id?: string }>();
    return next.handle().pipe(
      map((data) => ({
        success: true,
        data,
        meta: {
          requestId: request.id ?? 'untracked',
          timestamp: new Date().toISOString(),
          version: 'v1',
        },
      })),
    );
  }
}
