import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/domain/model_endpoint.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../data/agentic_search_orchestrator.dart';
import '../../data/azure_openai_client.dart';
import '../../data/gemini_client.dart';
import '../../data/ollama_client.dart';
import '../../data/openai_compatible_client.dart';
import '../../domain/chat_message.dart';
import '../../domain/conversation_thread.dart';
import '../../domain/llm_provider_client.dart';
import 'conversation_providers.dart';

class ChatState {
  const ChatState({
    required this.conversationId,
    this.title = 'New Conversation',
    this.messages = const [],
    this.isSending = false,
    this.searxngEnabled = false,
  });

  final String conversationId;
  final String title;
  final List<ChatMessage> messages;
  final bool isSending;
  final bool searxngEnabled;

  ChatState copyWith({
    String? conversationId,
    String? title,
    List<ChatMessage>? messages,
    bool? isSending,
    bool? searxngEnabled,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
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
  bool _bootstrapped = false;

  @override
  ChatState build() {
    final settings = ref.watch(settingsControllerProvider).value;
    final initial = ChatState(
      conversationId: _newConversationId(),
      searxngEnabled: settings?.searxngEnabledByDefault ?? false,
    );
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future<void>(() async {
        await _restoreLatestConversation();
      });
    }
    return initial;
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
    final title = state.messages.isEmpty ? _titleFrom(userInput) : state.title;
    state = state.copyWith(
      messages: nextMessages,
      isSending: true,
      title: title,
    );

    try {
      final settings =
          ref.read(settingsControllerProvider).value ?? const AppSettings();
      final endpoint = settings.selectedEndpoint;
      if (endpoint == null) {
        throw StateError('No model endpoint configured');
      }
      final client = _resolveClient(endpoint);
      final projectContext = await _buildProjectContext();
      final promptMessages = <ChatMessage>[
        if (settings.systemPrompt.trim().isNotEmpty)
          ChatMessage(role: 'system', content: settings.systemPrompt.trim()),
        if (projectContext.trim().isNotEmpty)
          ChatMessage(role: 'system', content: projectContext),
        ...nextMessages,
      ];
      final completion = state.searxngEnabled
          ? await AgenticSearchOrchestrator(
              searxngBaseUrl: settings.searxngBaseUrl,
            ).answerWithSearch(
              messages: promptMessages,
              llmClient: client,
              settings: settings,
            )
          : await client.completeChat(
              messages: promptMessages,
              enableSearch: false,
            );
      final inputTokens = completion.inputTokens > 0
          ? completion.inputTokens
          : _estimateTokens(promptMessages.map((e) => e.content).join('\n'));
      final outputTokens = completion.outputTokens > 0
          ? completion.outputTokens
          : _estimateTokens(completion.content);
      await ref
          .read(settingsControllerProvider.notifier)
          .recordUsage(
            endpointId: endpoint.id,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          );
      final artifact = _extractArtifact(completion.content);

      state = state.copyWith(
        messages: [
          ...nextMessages,
          ChatMessage(
            role: 'assistant',
            content: artifact.displayText,
            artifactHtml: artifact.html,
          ),
        ],
        isSending: false,
      );
      await _persistCurrentConversation();
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
      await _persistCurrentConversation();
    }
  }

  Future<void> loadConversation(ConversationThread thread) async {
    state = state.copyWith(
      conversationId: thread.id,
      title: thread.title,
      messages: thread.messages,
    );
  }

  Future<void> startNewConversation() async {
    state = state.copyWith(
      conversationId: _newConversationId(),
      title: 'New Conversation',
      messages: const [],
    );
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

  int _estimateTokens(String text) {
    final chars = text.runes.length;
    final estimated = (chars / 4).ceil();
    return estimated < 1 ? 1 : estimated;
  }

  _ArtifactExtraction _extractArtifact(String raw) {
    final fenced = RegExp(r'```html\s*([\s\S]*?)```', caseSensitive: false);
    final match = fenced.firstMatch(raw);
    if (match != null) {
      final html = (match.group(1) ?? '').trim();
      final plain = raw.replaceFirst(fenced, '').trim();
      return _ArtifactExtraction(
        displayText: plain.isEmpty ? '(artifact generated)' : plain,
        html: html.isEmpty ? null : html,
      );
    }

    final lowered = raw.toLowerCase();
    if (lowered.contains('<html') || lowered.contains('<!doctype html')) {
      return _ArtifactExtraction(
        displayText: '(artifact generated)',
        html: raw,
      );
    }
    return _ArtifactExtraction(displayText: raw, html: null);
  }

  Future<String> _buildProjectContext() async {
    try {
      final repository = ref.read(projectRepositoryProvider);
      final activeId = await repository.getActiveProjectId();
      if (activeId == null || activeId.isEmpty) {
        return '';
      }
      final project = await repository.getById(activeId);
      if (project == null) {
        return '';
      }

      final lines = <String>[];
      lines.add('Project: ${project.name}');
      if (project.additionalSystemPrompt.trim().isNotEmpty) {
        lines.add('Project Prompt:\n${project.additionalSystemPrompt.trim()}');
      }
      if (project.attachments.isNotEmpty) {
        lines.add('Project Attachments:');
      }

      for (final attachment in project.attachments.take(5)) {
        try {
          final file = File(attachment.path);
          if (!await file.exists()) {
            lines.add('- ${attachment.name}: (file missing)');
            continue;
          }
          final text = await file.readAsString();
          final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
          final excerpt = normalized.length > 500
              ? '${normalized.substring(0, 500)}...'
              : normalized;
          lines.add('- ${attachment.name}: $excerpt');
        } catch (_) {
          lines.add('- ${attachment.name}: (unreadable)');
        }
      }
      return lines.join('\n\n');
    } catch (_) {
      return '';
    }
  }

  Future<void> _restoreLatestConversation() async {
    try {
      final repository = ref.read(conversationRepositoryProvider);
      final list = await repository.list();
      if (list.isNotEmpty) {
        await loadConversation(list.first);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Restore latest conversation failed', error, stackTrace);
    }
  }

  Future<void> _persistCurrentConversation() async {
    try {
      final repository = ref.read(conversationRepositoryProvider);
      final thread = ConversationThread(
        id: state.conversationId,
        title: state.title,
        updatedAt: DateTime.now(),
        messages: state.messages,
      );
      await repository.upsert(thread);
      ref.invalidate(conversationListProvider);
    } catch (error, stackTrace) {
      AppLogger.error('Persist conversation failed', error, stackTrace);
    }
  }

  String _newConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  }

  String _titleFrom(String text) {
    final clean = text.trim().replaceAll('\n', ' ');
    if (clean.isEmpty) {
      return 'Conversation';
    }
    return clean.length <= 32 ? clean : '${clean.substring(0, 32)}...';
  }
}

class _ArtifactExtraction {
  const _ArtifactExtraction({required this.displayText, required this.html});

  final String displayText;
  final String? html;
}
