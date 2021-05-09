ARG JUPYTERHUB_VERSION

FROM jupyterhub/jupyterhub:${JUPYTERHUB_VERSION}

RUN apt-get update && apt-get install -yq --no-install-recommends \
	vim git wget  \
    libmemcached-dev \
    libsqlite3-dev \
    libzmq3-dev \
    pandoc \
    sqlite3 \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*  && hash -r


RUN pip install --upgrade pip \
    && pip install --quiet \
        jupyterhub-idle-culler \
        dockerspawner \
        oauthenticator

WORKDIR /srv

CMD ["jupyterhub", "-f", "/etc/jupyterhub/jupyterhub_config.py"]
