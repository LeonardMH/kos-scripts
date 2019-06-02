function notify_colored {
  parameter message.
  parameter color.

  hudtext("kOS: " + message, 5, 2, 24, color, true).
}

function notify {
  parameter message.
  notify_colored(message, WHITE).
}
