# Home Assistant Add-on: Supernote Private Cloud

## Installation

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**.
2. Click the **⋮** menu (top right) > **Repositories**, and add:
   `https://github.com/tomasbedrich/supernote`
3. Find **Supernote Private Cloud** in the store and click **Install**.

## First run

1. Start the add-on.
2. (Recommended) Set `initial_admin_email` and `initial_admin_password` in
   the add-on **Configuration** tab *before* the first start, then start
   (or restart) the add-on. It will automatically create your admin account
   a few seconds after the server comes up.
   - If you skip this, you can create the admin account later from a shell
     with access to the add-on container, e.g. using the *Terminal & SSH*
     add-on:
     ```bash
     docker exec addon_local_supernote supernote admin \
       --url http://localhost:8080 user add you@example.com
     ```
3. Note the IP address of your Home Assistant host (e.g. `192.168.1.5`).

## Connect your Supernote device

1. On your Supernote, go to **Settings > Sync > Private Cloud**.
2. Enter your server URL, e.g. `http://192.168.1.5:8080`.
3. Log in with the email/password created above.
4. Tap **Sync**.

If your device can't reach the server, check that your Home Assistant host's
firewall allows inbound connections on port `8080` from your LAN, and that
port `8080` isn't already in use by something else (change the left-hand
side of the port mapping in the add-on's **Network** settings if so; the
right-hand side, `8080`, is what the app listens on internally).

## Configuration options

| Option | Description |
|---|---|
| `base_url` | Advanced. Leave this empty — the add-on already generates correct device sync/download URLs per-request without it. Only set it if you put an HTTPS reverse proxy in front of the add-on and want the optional MCP server reachable externally; it must then be `https://...` or a bare `http://localhost:8080` / `http://127.0.0.1:8080`. Any other `http://` value (e.g. a LAN IP or `homeassistant.local`) makes the server crash on startup — it also doubles as the MCP OAuth issuer, which RFC 8414 requires to be HTTPS except on loopback. |
| `initial_admin_email` / `initial_admin_password` | If both are set, the add-on creates this admin user automatically on first start. Only takes effect once (tracked with a marker file in the add-on's data directory) — change the password later via the CLI or the web UI. |
| `enable_registration` | Allow public self-service registration. Off by default; the first user can always be created via the CLI/bootstrap regardless of this setting. |
| `enable_remote_password_reset` | Allow the public "forgot password" flow. Off by default. |
| `gemini_api_key` | Google Gemini API key. Set this to enable AI transcription, summarization, and semantic search. |
| `gemini_ocr_model` / `gemini_embedding_model` | Override the default Gemini models used for OCR / embeddings. Leave empty to use the built-in defaults. |
| `jwt_secret` | Fixed secret used to sign session tokens. Leave empty to let the add-on generate and persist one automatically on first start. Only set this if you need a stable, known secret (e.g. migrating an existing non-add-on deployment). |

## Data & backups

All data (the SQLite database, uploaded notebooks, and generated config)
lives under the add-on's persistent `/data` directory, which Home Assistant
includes in Supervisor snapshots/backups automatically.

## Ports

| Port | Purpose |
|---|---|
| `8080/tcp` | Web UI, admin API, and the endpoint your Supernote device syncs to. |
| `8081/tcp` | MCP server for connecting AI agents to your notes (optional; see the [MCP docs](https://github.com/tomasbedrich/supernote/blob/main/docs/mcp.md)). |

## Updating

Update the add-on from the Home Assistant Add-on Store like any other
add-on. Your data in `/data` is preserved across updates.

## Troubleshooting

- Check the add-on **Log** tab for server output.
- If you changed `initial_admin_email`/`initial_admin_password` after the
  first successful bootstrap, nothing will happen (the bootstrap only runs
  once per install) — use the CLI to reset a password instead:
  ```bash
  docker exec addon_local_supernote supernote admin \
    --url http://localhost:8080 user reset-password you@example.com
  ```
- If the log ends with `ValueError: Issuer URL must be HTTPS` and the add-on
  won't start, you have a non-empty `base_url` option set to a plain
  `http://` address other than `localhost`/`127.0.0.1`. Clear the `base_url`
  field and restart — see the configuration table above.
- For more background on the underlying project, see the
  [main project README](https://github.com/tomasbedrich/supernote).
