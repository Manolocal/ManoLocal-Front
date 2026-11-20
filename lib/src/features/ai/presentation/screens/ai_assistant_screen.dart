import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ai_provider.dart';

/// Asistente inteligente impulsado por Google Gemini AI (`GET /ai/status` + `POST /ai/generate-text`).
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AiProvider>().loadStatus();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _promptsForRole(UserRole role) {
    if (role == UserRole.especialista) {
      return const [
        'Redacta una descripción profesional y breve para un trabajo de instalación de calentador solar en mi catálogo.',
        'Ayúdame a escribir un mensaje cordial para enviar una cotización de plomería a un cliente en ManoLocal.',
        'Sugiere 5 nombres claros de oficios relacionados con electricidad residencial para mi perfil.',
      ];
    }
    return const [
      'Tengo una fuga de agua debajo del lavabo, ¿qué oficio debo buscar y qué detalles debo dar para cotizar?',
      'Ayúdame a redactar un mensaje claro para solicitar presupuesto de pintura interior de 2 habitaciones.',
      '¿Qué aspectos debo revisar antes de marcar un trabajo de electricidad como completado?',
    ];
  }

  Future<void> _sendPrompt([String? preset]) async {
    final text = (preset ?? _promptController.text).trim();
    if (text.isEmpty) return;

    _promptController.clear();
    FocusScope.of(context).unfocus();

    final ok = await context.read<AiProvider>().askAssistant(text);
    if (!ok && mounted) {
      final err = context.read<AiProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final role = context.watch<AuthProvider>().user?.role ?? UserRole.empleador;
    final status = ai.status;
    final suggestions = _promptsForRole(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA ManoLocal'),
        actions: [
          if (ai.turns.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar conversación',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ai.clearConversation(),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.gray,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.yellow,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status == null
                        ? 'Conectado al motor de IA de ManoLocal'
                        : '${status.model.isNotEmpty ? status.model : 'Google Gemini'} · ${status.isConfigured ? 'Activo' : 'Modo demostración'}',
                    style: const TextStyle(
                      color: AppColors.silver,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ai.turns.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const EmptyStateView(
                                icon: Icons.auto_awesome_rounded,
                                title: '¿En qué te ayudo hoy?',
                                description:
                                    'Pide ayuda para cotizar servicios, redactar descripciones de trabajos o elegir el oficio ideal.',
                              ),
                              const SizedBox(height: 8),
                              const SectionHeader(
                                title: 'Sugerencias rápidas',
                              ),
                              const SizedBox(height: 10),
                              ...suggestions.map(
                                (prompt) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.tips_and_updates_outlined,
                                        color: AppColors.yellowDark,
                                      ),
                                      title: Text(
                                        prompt,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing:
                                          const Icon(Icons.send_rounded, size: 18),
                                      onTap: ai.isGenerating
                                          ? null
                                          : () => _sendPrompt(prompt),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: ai.turns.length + (ai.isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == ai.turns.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Gemini está redactando...'),
                              ],
                            ),
                          ),
                        );
                      }

                      final turn = ai.turns[index];
                      return _AiTurnBubble(turn: turn);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendPrompt(),
                      decoration: InputDecoration(
                        hintText: 'Pregúntale al asistente ManoLocal...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.yellow,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: ai.isGenerating ? null : () => _sendPrompt(),
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiTurnBubble extends StatelessWidget {
  final AiAssistantTurn turn;

  const _AiTurnBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: turn.isUser
              ? AppColors.gray
              : (isDark ? AppColors.graySurface : AppColors.white),
          borderRadius: BorderRadius.circular(16),
          border: turn.isUser
              ? null
              : Border.all(
                  color: isDark ? AppColors.grayElevated : AppColors.silver,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!turn.isUser)
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: AppColors.yellowDark,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Asistente Gemini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copiar respuesta',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: turn.text));
                      GlobalNotifier.showInfoSnackBar('Texto copiado');
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            SelectableText(
              turn.text,
              style: TextStyle(
                color: turn.isUser
                    ? AppColors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
