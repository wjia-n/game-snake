import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garden.dart';
import '../theme/garden_themes.dart';

/// Renameable player profile dialog.
///
/// - Saves on EVERY keystroke ([SnakeSettings.saveNameDraft]).
/// - Commits on focus loss, on submit, and on the Save button.
/// - Cancel reverts to the name the dialog opened with.
///
/// The typing field owns its own controller; draft writes never notify, so
/// the keyboard is never fought mid-keystroke.
Future<void> showRenameDialog({
  required BuildContext context,
  required SnakeSettings settings,
  required SnakeAudio audio,
  required GardenThemeDef theme,
}) async {
  final initial = settings.playerName;
  final ctrl = TextEditingController(text: initial);
  final focus = FocusNode();
  var committed = false;

  Future<void> commit() async {
    if (committed) return;
    committed = true;
    await settings.setPlayerName(ctrl.text);
  }

  focus.addListener(() {
    if (!focus.hasFocus) unawaited(commit()); // commit on focus loss
  });

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.backdropMid,
      title: Text('Your name', style: Garden.display(20, theme: theme)),
      content: TextField(
        controller: ctrl,
        focusNode: focus,
        autofocus: true,
        maxLength: 16,
        style: Garden.body(17, theme: theme),
        decoration: InputDecoration(
          hintText: 'What should the meadow call you?',
          hintStyle: Garden.body(14,
              theme: theme,
              color: theme.ink.withValues(alpha: 0.5)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accent)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accentLight, width: 2)),
        ),
        onChanged: (v) {
          unawaited(settings.saveNameDraft(v)); // every keystroke
        },
        onSubmitted: (_) async {
          await commit();
          if (ctx.mounted) Navigator.of(ctx).pop(true);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: Garden.label(14, theme: theme)),
        ),
        TextButton(
          onPressed: () async {
            await commit();
            if (ctx.mounted) Navigator.of(ctx).pop(true);
          },
          child: Text('Save', style: Garden.label(14, theme: theme)),
        ),
      ],
    ),
  );
  if (result == false) {
    // Cancel: revert to the name we opened with.
    await settings.setPlayerName(initial);
    unawaited(audio.click());
  } else if (result == true) {
    unawaited(audio.click());
  }
  ctrl.dispose();
  focus.dispose();
}
