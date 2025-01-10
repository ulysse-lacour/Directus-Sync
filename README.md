# Directus Sync

## *Directus Sync*

To use it you'll need globally installed [pnpm](https://github.com/pnpm/pnpm) and [nvm](https://github.com/nvm-sh/nvm) and obviously Docker.

Happy coding !

## Scripts

A few utils scripts are included, they all can be run from root via pnpm.

- `dev`: launch app in dev mode
- `backup`: backup postgres database and directus uploads folder
- `restore`: restore postgres and directus uploads from local availables backups
- `template-export`: export local directus app as a template
- `template-apply`: apply template to local directus app

## Setup

First of all create `.env` files based on `.env.example`.

Then you'll need to run from root folder :

```bash
# Start app
pnpm dev

# In Directus create an admin token
# Directus --> User Directory --> Admin User --> Generate Token --> Copy Token --> Save User

# Add token to your .env file and restart containers with
pnpm dev

# Apply base theme template
pnpm template-apply
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
