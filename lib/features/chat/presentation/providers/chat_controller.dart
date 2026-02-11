import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/domain/model_endpoint.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../data/azure_openai_client.dart';
import '../../data/gemini_client.dart';
import '../../data/ollama_client.dart';
import '../../data/openai_compatible_client.dart';
import '../../domain/chat_message.dart';
import '../../domain/llm_provider_client.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.searxngEnabled = false,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final bool searxngEnabled;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? searxngEnabled,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      searxngEnabled: searxngEnabled ?? this.searxngEnabled,
    );
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    final settings = ref.watch(settingsControllerProvider).value;
    return ChatState(
      searxngEnabled: settings?.searxngEnabledByDefault ?? false,
    );
  }

  void toggleSearxng(bool enabled) {
    state = state.copyWith(searxngEnabled: enabled);
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || state.isSending) {
      return;
    }

    final userMessage = ChatMessage(role: 'user', content: userInput.trim());
    final nextMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: nextMessages, isSending: true);

    try {
      final settings =
          ref.read(settingsControllerProvider).value ?? const AppSettings();
      final endpoint = settings.selectedEndpoint;
      if (endpoint == null) {
        throw StateError('No model endpoint configured');
      }
      final client = _resolveClient(endpoint);
      final promptMessages = <ChatMessage>[
        if (settings.systemPrompt.trim().isNotEmpty)
          ChatMessage(role: 'system', content: settings.systemPrompt.trim()),
        ...nextMessages,
      ];
      final content = await client.completeChat(
        messages: promptMessages,
        enableSearch: state.searxngEnabled,
      );

      state = state.copyWith(
        messages: [
          ...nextMessages,
          ChatMessage(role: 'assistant', content: content),
        ],
        isSending: false,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Chat send failed', error, stackTrace);
      state = state.copyWith(
        messages: [
          ...nextMessages,
          ChatMessage(
            role: 'assistant',
            content: 'エラー: 選択中モデルへの接続に失敗しました。設定を確認してください。',
          ),
        ],
        isSending: false,
      );
    }
  }

  LlmProviderClient _resolveClient(ModelEndpoint endpoint) {
    final dio = Dio(
      BaseOptions(
        baseUrl: endpoint.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return switch (endpoint.provider) {
      LlmProviderType.ollama => OllamaClient(
        dio: dio,
        model: endpoint.model,
        temperature: endpoint.temperature,
        maxTokens: endpoint.maxTokens,
      ),
      LlmProviderType.lmStudio => OpenAiCompatibleClient(
        dio: dio,
        model: endpoint.model,
        temperature: endpoint.temperature,
        maxTokens: endpoint.maxTokens,
        apiKey: endpoint.apiKey,
      ),
      LlmProviderType.llamaCpp => OpenAiCompatibleClient(
        dio: dio,
        model: endpoint.model,
        temperature: endpoint.temperature,
        maxTokens: endpoint.maxTokens,
        apiKey: endpoint.apiKey,
      ),
      LlmProviderType.gemini => GeminiClient(
        dio: dio,
        model: endpoint.model,
        apiKey: endpoint.apiKey,
        temperature: endpoint.temperature,
        maxTokens: endpoint.maxTokens,
      ),
      LlmProviderType.azureOpenAi => AzureOpenAiClient(
        dio: dio,
        deployment: endpoint.model,
        apiKey: endpoint.apiKey,
        apiVersion: endpoint.apiVersion,
        temperature: endpoint.temperature,
        maxTokens: endpoint.maxTokens,
      ),
    };
  }
}
