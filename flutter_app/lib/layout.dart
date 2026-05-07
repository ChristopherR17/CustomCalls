import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:provider/provider.dart';

import 'app_data.dart';
import 'canvas_painter.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  final List<String> _placeholders = const [
    'Dibuixa un cercle blau amb contorn negre al centre',
    'Dibuixa un rectangle amb degradat de vermell a groc',
    'Dibuixa una línia verda de gruix 6 en diagonal',
    'Escriu “Hola” en negreta a la meitat del dibuix',
    'Canvia la figura seleccionada a color rosa',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final random = Random();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        appData.setCanvasSize(size);

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) => appData.selectAt(details.localPosition),
                          child: CustomPaint(
                            painter: CanvasPainter(drawables: appData.drawables),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: Container(
                    color: const Color(0xFFF4F5F8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Eina vectorial IA',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appData.selectedId == null
                                    ? 'Cap figura seleccionada'
                                    : 'Seleccionada: ${appData.selectedId}',
                                style: const TextStyle(
                                  color: Color(0xFF5F6368),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: CupertinoScrollbar(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    appData.responseText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Color(0xFF2B2B2B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: CDKFieldText(
                            maxLines: 5,
                            controller: _textController,
                            placeholder: _placeholders[random.nextInt(_placeholders.length)],
                            enabled: !appData.isLoading,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CDKButton(
                                      style: CDKButtonStyle.action,
                                      onPressed: appData.isLoading
                                          ? null
                                          : () {
                                              final userPrompt = _textController.text.trim();
                                              if (userPrompt.isEmpty) return;
                                              appData.callWithCustomTools(userPrompt: userPrompt);
                                            },
                                      child: const Text('Enviar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CDKButton(
                                      onPressed: appData.isLoading ? () => appData.cancelRequests() : null,
                                      child: const Text('Cancel·lar'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: CDKButton(
                                      onPressed: appData.drawables.isEmpty ? null : () => appData.clearCanvas(),
                                      child: const Text('Netejar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CDKButton(
                                      onPressed: appData.selectedId == null ? null : () => appData.deleteSelected(),
                                      child: const Text('Esborrar selecció'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (appData.isLoading)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.systemGrey.withOpacity(0.35),
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
