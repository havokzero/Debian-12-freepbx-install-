# FreePBX 16 One-Shot Installer (Debian 12)

This repository contains a single, opinionated installer script that deploys a fully working FreePBX 16 system on Debian 12, including:

- Asterisk 18 (built from source)
- FreePBX 16
- Apache
- MariaDB
- PHP 7.4.x (explicitly required)
- Node.js / npm
- All required build and runtime dependencies

This exists to solve the classic failure mode on Debian 12:
Asterisk installs fine, but there is no FreePBX web UI and /var/www/html is empty.

That is not an Apache problem. It is a missing FreePBX install. This script fixes that.

---

IMPORTANT WARNINGS

- Intended for fresh Debian 12 systems
- Disables PHP 8.x Apache modules
- Installs PHP 7.4 (required by FreePBX 16)
- Not production hardened
- Must be run as root

If you want PHP 8.x, you want FreePBX 17. This script is not for that.

---

WHAT THIS SCRIPT DOES

- Verifies Debian 12 and root access
- Installs all required dependencies
- Installs PHP 7.4 from packages.sury.org
- Configures Apache correctly for FreePBX
- Builds and installs Asterisk 18
- Creates and configures the asterisk user
- Installs FreePBX 16
- Deploys the FreePBX web UI to /var/www/html
- Verifies admin/config.php exists
- Prints the correct access URL at the end
- Fails loudly if anything breaks

If /var/www/html is empty after this script runs, the script will exit with an error instead of lying to you.

---

REQUIREMENTS

- Debian 12 (Bookworm)
- Internet access
- Root shell
- Fresh VM strongly recommended

---

USAGE

1. Copy the installer script to your system
2. Make it executable
3. Run it as root

Example:

  chmod +x install_freepbx16_debian12.sh
  sudo ./install_freepbx16_debian12.sh

No prompts. No interactive nonsense.

---

AFTER INSTALLATION

When the script completes successfully, it prints something like:

  FreePBX INSTALL COMPLETE
  Access: http://<IP_ADDRESS>/admin/config.php

Open that URL in a browser to finish the FreePBX web setup.

---

COMMON FAILURE CAUSES (HANDLED BY THE SCRIPT)

- PHP 8.x still loaded in Apache
- Node.js or npm missing
- MariaDB not running or root auth broken
- Asterisk not started before FreePBX install
- Running the installer from the wrong directory

The script stops immediately when one of these occurs and prints a clear error message.

---

WHAT THIS SCRIPT DOES NOT DO

- HTTPS / TLS
- Firewall configuration
- Fail2ban
- Production security hardening
- FreePBX commercial module licensing

Those are intentionally excluded. This script gets you to a working system, not a compliance checklist.

---

TESTED WITH

- Debian 12 (Bookworm)
- FreePBX 16.0-latest
- Asterisk 18-current
- PHP 7.4.33+

---

WHY THIS EXISTS

Because reinstalling Asterisk repeatedly does not create a web UI.

FreePBX is a separate application. This script installs it correctly.

---

LICENSE

MIT. Use it, fork it, fix it, complain about it.
Just don’t point it at a cursed server and act surprised.
