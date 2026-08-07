import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Logs'),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            onPressed: () async {
              await logger.copyToClipboard();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy_all_rounded),
          ),
          IconButton(
            tooltip: 'Clear logs',
            onPressed: () async {
              await logger.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: logger,
        builder: (context, _) {
          final text = logger.fullText.trim().isEmpty
              ? 'No logs recorded yet.\n\nLog file:\n${logger.logFilePath ?? 'Not available'}'
              : '${logger.fullText}\n\n--- Log file ---\n${logger.logFilePath ?? 'Not available'}';
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete log copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy complete log'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    final text = 'Fatal application error\n\n$error\n\n$stackTrace';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Application Error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'The application could not start. Copy the message below and send it for review.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy error'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
