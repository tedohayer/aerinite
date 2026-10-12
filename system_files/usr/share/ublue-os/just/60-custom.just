# Aerinite recipes (base-main's justfile imports this file if it exists)

# Turn the update notifications ("Update ready", "out of date") on or off (on by default)
toggle-update-notifications:
    #!/usr/bin/bash
    units=(aerinite-update-notify.path aerinite-update-age.timer)
    if [ "$(systemctl --user is-enabled aerinite-update-notify.path)" = masked ]; then
        systemctl --user unmask "${units[@]}"
        systemctl --user start "${units[@]}"
        echo "Update notifications: on"
    else
        systemctl --user mask --now "${units[@]}"
        echo "Update notifications: off"
    fi
