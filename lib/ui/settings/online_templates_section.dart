import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoard_game/application/models/templates/online_template_status.dart';
import 'package:scoard_game/application/services/templates/online_templates.dart';

/// The Templates part of Settings: whether to load templates online, from
/// where, and how the last check went.
class OnlineTemplatesSection extends StatelessWidget {
  const OnlineTemplatesSection({
    required this.onlineTemplates,
    this.now,
    super.key,
  });

  final OnlineTemplates onlineTemplates;

  /// For tests. Defaults to the clock.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: onlineTemplates,
      builder: (context, _) {
        final status = onlineTemplates.status;
        final problemCount = status?.problems.length ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Templates', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Get template updates without updating the app.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: onlineTemplates.enabled,
                    onChanged: (enabled) =>
                        unawaited(onlineTemplates.setEnabled(enabled)),
                    title: const Text('Load templates online'),
                    subtitle: const Text(
                      'Checks once when the app starts. Built-in templates are '
                      'used when offline.',
                    ),
                  ),
                  if (onlineTemplates.enabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Template URL'),
                      subtitle: Text(onlineTemplates.url),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editUrl(context),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusText(
                                status,
                                isChecking: onlineTemplates.isChecking,
                                now: (now ?? DateTime.now)(),
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            onPressed: onlineTemplates.isChecking
                                ? null
                                : () => unawaited(onlineTemplates.checkNow()),
                            child: onlineTemplates.isChecking
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Check now'),
                          ),
                        ],
                      ),
                    ),
                    if (problemCount > 0)
                      ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          problemCount == 1
                              ? '1 template has problems'
                              : '$problemCount templates have problems',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showProblems(context, status!.problems),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editUrl(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TemplateUrlDialog(onlineTemplates: onlineTemplates),
    );
  }

  Future<void> _showProblems(
    BuildContext context,
    Map<String, List<String>> problems,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Template problems'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'These files were skipped. Each keeps its last good copy, '
                  'if there is one.',
                ),
                for (final entry in problems.entries) ...[
                  const SizedBox(height: 16),
                  Text(entry.key, style: theme.textTheme.titleSmall),
                  for (final problem in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(problem, style: theme.textTheme.bodySmall),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

String _statusText(
  OnlineTemplateStatus? status, {
  required bool isChecking,
  required DateTime now,
}) {
  if (isChecking) {
    return 'Checking for templates…';
  }
  if (status == null || status.lastChecked == null) {
    return 'Not checked yet.';
  }

  final count = status.templateCount;
  final using = count == 0
      ? 'Using built-in templates.'
      : 'Using $count online template${count == 1 ? '' : 's'}.';
  final error = status.lastError;
  if (error != null) {
    return 'Last check failed ${describeWhen(status.lastChecked!, now)}: '
        '$error. $using';
  }
  return 'Checked ${describeWhen(status.lastChecked!, now)}. $using';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "just now", "5 minutes ago", "3 hours ago", or "on 12 Oct".
String describeWhen(DateTime when, DateTime now) {
  final elapsed = now.difference(when);
  if (elapsed.inMinutes < 1) {
    return 'just now';
  }
  if (elapsed.inHours < 1) {
    final minutes = elapsed.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
  if (elapsed.inDays < 1) {
    final hours = elapsed.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }
  return 'on ${when.day} ${_months[when.month - 1]}';
}

class _TemplateUrlDialog extends StatefulWidget {
  const _TemplateUrlDialog({required this.onlineTemplates});

  final OnlineTemplates onlineTemplates;

  @override
  State<_TemplateUrlDialog> createState() => _TemplateUrlDialogState();
}

class _TemplateUrlDialogState extends State<_TemplateUrlDialog> {
  late final _controller =
      TextEditingController(text: widget.onlineTemplates.url);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(String url) {
    if (normalizeTemplateUrl(url) == null) {
      setState(() => _error = 'Enter an https:// address.');
      return;
    }
    // Saving starts a check; the dialog closes without waiting for it.
    unawaited(widget.onlineTemplates.setUrl(url));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Template URL'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'The folder that holds index.json and the template files.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(errorText: _error),
            onSubmitted: _save,
          ),
        ],
      ),
      actions: [
        if (_controller.text != defaultTemplateUrl)
          TextButton(
            onPressed: () => _save(defaultTemplateUrl),
            child: const Text('Use default'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _save(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
