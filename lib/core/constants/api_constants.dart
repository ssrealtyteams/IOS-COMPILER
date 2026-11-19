abstract class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ssrealty.org/api/mobile',
  );
  static const fallbackLocalUrl = 'https://ssrealty.org/api/mobile';
  static const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://ssrealty.org',
  );
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 60);

  // Endpoints
  static const auth = '/auth';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const refresh = '/auth/refresh';
  static const sessions = '/auth/sessions';

  static const leads = '/leads';
  static const calls = '/calls';
  static const followups = '/followups';
  static const visits = '/visits';
  static const projects = '/projects';
  static const dashboard = '/dashboard';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const sync = '/sync';
  static const users = '/users';
  static const media = '/media';
}
