# Reminder

A small Lazarus/Free Pascal desktop reminder app inspired by an older Delphi tray reminder project.

The default main window title is **Look Away!**.

## Features in this starter version

- Preset reminders: 5, 10, 15, 30 minutes; 1, 2, 4, 8 hours
- Custom minutes
- Exact date/time input using `yyyy-mm-dd hh:mm:ss`
- Periodic due-time checking instead of one huge timer interval
- Saved reminder state using the platform app config file
- Tray icon with Show, Stop, and Exit menu items
- GitHub Actions build workflow for Windows, Ubuntu Linux, and Rocky Linux 9

## Build locally, optional

```bash
lazbuild src/reminder.lpi --build-mode=Release
```

The executable is written to `build/reminder` or `build/reminder.exe`.
