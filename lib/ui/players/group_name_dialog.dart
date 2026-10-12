import 'package:flutter/material.dart';
import 'package:scoard_game/application/services/players/create_player.dart';

/// Asks for a group name and runs [onSubmit] with it. Validation errors from
/// [onSubmit] are shown in the dialog instead of closing it.
Future<T?> showGroupNameDialog<T>(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Future<T> Function(String name) onSubmit,
  String initialValue = '',
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => _GroupNameDialog<T>(
      title: title,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      onSubmit: onSubmit,
    ),
  );
}

class _GroupNameDialog<T> extends StatefulWidget {
  const _GroupNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialValue,
    required this.onSubmit,
  });

  final String title;
  final String confirmLabel;
  final String initialValue;
  final Future<T> Function(String name) onSubmit;

  @override
  State<_GroupNameDialog<T>> createState() => _GroupNameDialogState<T>();
}

class _GroupNameDialogState<T> extends State<_GroupNameDialog<T>> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  String? _errorText;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Group name',
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    try {
      final result = await widget.onSubmit(_controller.text);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on PlayerValidationException catch (error) {
      if (mounted) {
        setState(() {
          _errorText = error.message;
          _isSaving = false;
        });
      }
    }
  }
}
