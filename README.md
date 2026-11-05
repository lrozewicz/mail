# mail

Mail server ([Stalwart](https://stalw.art), SMTP/IMAP/JMAP) and webmail ([SnappyMail](https://snappymail.eu))
for the OVH platform (`lrozewicz/platform-gitops`, `apps/mail`).

| | dev | prod |
|---|---|---|
| Mail server (web admin/JMAP) | https://mail.dev.lucasnextgen.com | https://mail.lucasnextgen.com |
| Webmail | https://webmail.dev.lucasnextgen.com | https://webmail.lucasnextgen.com |

Mail ports (25, 465, 587, 993) are public on **prod only**; dev has no public mail ports (one IP, one port 25).

## Images

- `docker/stalwart`: official Stalwart image (tag + digest pinned), UID 10001, read-only root, no file
  capabilities. Data (mail, blobs, settings) lives in MariaDB (chart `database`), so the platform backups
  (daily dump to S3) are consistent. `entrypoint.sh` renders the local `config.json` (data store only)
  from `DB_*`; the password is read by Stalwart from the environment, never written to disk.
- `docker/snappymail`: SnappyMail 2.38.2 (SHA-256 pinned) on nginx + PHP-FPM, UID 10001, read-only root,
  data in `/data`. Declarative: the mail server domain and `application.ini` are generated from env;
  the SnappyMail admin panel is **off** (`SNAPPYMAIL_ADMIN=1` turns it on, for debugging over a port-forward).
  PHP is locked down (`open_basedir`, `disable_functions`); nginx denies data, sources and dotfiles.

Each image has a `test` stage (syntax, config rendering, nginx/php-fpm config checks) used by CI.

## Local check

```bash
docker build --target test docker/stalwart && docker build --target test docker/snappymail
```
