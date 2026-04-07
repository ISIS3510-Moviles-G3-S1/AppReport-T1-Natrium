import 'secrets.dart';

class APIConfig {
  APIConfig._();

  static const String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String openRouterApiKey = Secrets.openRouterApiKey;
  static const String openRouterModel = Secrets.openRouterModel;
}
