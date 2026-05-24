# Reminder

A Lazarus/Free Pascal rewrite of the original Delphi `watch out!` reminder app, renamed to **Reminder** with the default alarm name/window title **Look Away!**.

This version intentionally restores the original two-window behavior:

- main settings form with the original preset buttons: 5, 10, 15, 20, 30, 40 minutes, 1 hour, 2 hours
- manual minute/hour postponing
- exact date/time scheduling
- 20-second beep test button
- second borderless status form showing the next alarm time
- main form hides after a reminder is chosen
- tray icon while a reminder is active
- stop/hide/exit behavior
- stay-on-top behavior for both forms
- fade behavior on the second form
- saved reminder state via an INI config file

Builds are handled by GitHub Actions for Windows, Ubuntu Linux, and Rocky Linux 9.
