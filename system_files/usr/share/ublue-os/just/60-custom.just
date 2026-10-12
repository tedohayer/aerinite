# Aerinite recipes (base-main's justfile imports this file if it exists)

# Turn the "Update ready" notification on or off (on by default)
toggle-update-notification:
    #!/usr/bin/bash
    if [ "$(systemctl --user is-enabled aerinite-update-notify.path)" = masked ]; then
        systemctl --user unmask aerinite-update-notify.path
        systemctl --user start aerinite-update-notify.path
        echo "Update notification: on"
    else
        systemctl --user mask --now aerinite-update-notify.path
        echo "Update notification: off"
    fi
