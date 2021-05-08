FROM ubuntu:focal-20210416

# Notice: part of this code is from jupyter project
LABEL MAINTAINER Roger Mähler <roger dot mahler at umu dot se>

ARG TINI_VERSION=v0.18.0

ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN set -ex; \
    \
    apt-get update -qq && apt-get -y -qq dist-upgrade > /dev/null \
    \
    && mkdir -p /usr/share/man/man1 \
    && apt-get install -y -qq --no-install-recommends apt-utils \
        sudo locales software-properties-common \
        build-essential \
        wget curl zip unzip bzip2 llvm git vim gnupg \
        libssl-dev libopenblas-base zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev  \
        libncurses5-dev ca-certificates netbase netcat \
        python3 \
        python3-dev \
        python3-pip \
        python3-pycurl \
        python3-venv \
        nodejs npm yarn \
        fonts-liberation > /dev/null \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && npm install n -g \
    && n stable

RUN python3.8 -m venv /venv

ENV PATH="/venv/bin:/usr/local/bin:$PATH"
RUN echo "export PATH=${PATH}" >> /root/.bashrc

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini

RUN chmod +x /usr/local/bin/tini

ARG JUPYTERHUB_VERSION

RUN python --version \
    && pip install --quiet --upgrade pip \
    && pip install --quiet jupyterhub==${JUPYTERHUB_VERSION}

ARG PYPI_PACKAGE
ARG PYPI_PACKAGE_VERSION

RUN pip install --quiet ${PYPI_PACKAGE}==${PYPI_PACKAGE_VERSION}

COPY scripts/install-data.sh /tmp/install-data.sh

RUN mkdir -p /data \
    && chmod +x /tmp/install-data.sh \
    && /tmp/install-data.sh

RUN jupyter labextension install \
        ipyaggrid \
        @finos/perspective-jupyterlab \
        @jupyter-widgets/jupyterlab-manager

ENV NLTK_DATA=/usr/local/share/nltk_data

ENTRYPOINT ["tini", "-g", "--"]


ARG LAB_UID="201"
ARG LAB_GID="2001"
ARG LAB_USER="jovyan"

RUN addgroup --gid $LAB_GID "${LAB_USER}s"  \
    && adduser $LAB_USER --uid $LAB_UID --gid $LAB_GID --disabled-password --gecos '' --shell /bin/bash \
    && adduser $LAB_USER sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN  npm cache clean --force \
    && jupyter lab clean \
    && pip cache purge

ENV HOME=/home/$LAB_USER
USER $LAB_USER
WORKDIR $HOME

RUN mkdir -p $HOME/work

WORKDIR $HOME/work

COPY --chown=$LAB_USER:users scripts $HOME/work/scripts
COPY --chown=$LAB_USER:users data $HOME/work/data

ARG GITHUB_REPOSITORY_URL

RUN chmod +x $HOME/work/scripts/*.sh \
    && $HOME/work/scripts/update-notebooks.sh -r ${GITHUB_REPOSITORY_URL} notebooks resources __paths__.py

CMD ["jupyterhub-singleuser"]
# CMD jupyter lab --ip=* --port=${LAB_PORT} --no-browser --allow-root
