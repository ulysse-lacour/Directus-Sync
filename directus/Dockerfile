# syntax=docker/dockerfile:1.4

####################################################################################################
## Directus install extensions

FROM directus/directus:11.2


USER root

# Install pnpm and necessaries directus dependencies
RUN corepack enable \
    && corepack prepare pnpm@9.10 --activate

# Switch to node user for pnpm operations
USER node

# Workaround to be able to install extensions with 'node' user, only required in v11
RUN rm node_modules/.modules.yaml

EXPOSE ${PORT}

RUN pnpm install directus-template-cli@latest directus-extension-sync directus-sync directus-extension-models directus-auto-gen-extension directus-extension-classified-group && pnpm config set auto-install-peers true
CMD : \
    && node /directus/cli.js bootstrap \
    && node /directus/cli.js start \
    ;
