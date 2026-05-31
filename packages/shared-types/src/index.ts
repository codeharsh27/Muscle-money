export type ApiResponse<T> = {
  success: boolean;
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
    version: string;
  };
};

export type ApiErrorResponse = {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta: {
    requestId: string;
    timestamp: string;
    version: string;
  };
};

export enum UserRole {
  Student = 'STUDENT',
  Admin = 'ADMIN',
}
