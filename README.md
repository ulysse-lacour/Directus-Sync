# Directus Sync

## *Directus Sync*

To use it you'll need globally installed [pnpm](https://github.com/pnpm/pnpm) and [nvm](https://github.com/nvm-sh/nvm) and obviously Docker.

Happy coding !

## Scripts

A few utils scripts are included, they all can be run from root via pnpm.

- `dev`: launch app in dev mode
- `db:backup`: backup postgres database and directus uploads folder
- `db:restore`: restore postgres and directus uploads from local availables backups
- `config:pull`: export local directus config (using directus-sync extension)
- `config:push`: import local directus config (using directus-sync extension)
- `config:diff`: compare config from app and config-sync folder (using directus-sync extension)
- `template:pull`: export local directus app as a template (using directus-template-cli extension)
- `template:push`: apply template to local directus app (using directus-template-cli extension)

## Setup

First of all create `.env` files based on `.env.example`.

Then you'll need to run from root folder :

EITHER (for blank directus app) :

```bash
# Start app
pnpm dev

# In Directus create an admin token
# Directus --> User Directory --> Admin User --> Generate Token --> Copy Token --> Save User

# Add token to your .env file and restart containers with
pnpm dev

# Apply base theme template
pnpm template:push
```

OR :

```bash
# Start app
pnpm dev

# Apply config from config-sync
pnpm config:push

# Import backed up database
pnpm db:restore
```

<p float="middle">
    <img
        src="https://img.shields.io/badge/directus-%2364f.svg?style=for-the-badge&logo=directus&logoColor=white"
        alt="directus"
    />
    <img
        src="https://img.shields.io/badge/pnpm-%234a4a4a.svg?style=for-the-badge&logo=pnpm&logoColor=f69220"
        alt="pnpm"
    />
    <img
        src="https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white"
        alt="docker"
    />
    <img
        src="https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white"
        alt="postgres"
    />
</p>
