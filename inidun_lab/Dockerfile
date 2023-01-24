FROM ubuntu:20.04
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
        python3.9 \
        python3-pip \
        python3.9-dev \
        python3.9-venv \
        python3-pycurl \
        nodejs npm yarn \
        fonts-liberation > /dev/null \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && npm install n -g \
    && n stable

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini

ENTRYPOINT ["tini", "-g", "--"]

ARG LAB_UID="201"
ARG LAB_GID="2001"
ARG LAB_USER="jovyan"

RUN  addgroup --gid $LAB_GID "${LAB_USER}"  \
  && adduser $LAB_USER --uid $LAB_UID --gid $LAB_GID --disabled-password --gecos '' --shell /bin/bash \
  && adduser $LAB_USER sudo \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ARG NLTK_DATA
ARG SPACY_DATA
ENV NLTK_DATA=${NLTK_DATA}
ENV SPACY_DATA=${SPACY_DATA}

# COPY scripts/install-data.sh /tmp/install-data.sh
# RUN if [ "$SPACY_DATA" == "" ] ; then \
#         chmod +x /tmp/install-data.sh && /tmp/install-data.sh ; \
#     fi

RUN python3.9 -m venv /venv && . /venv/bin/activate
ENV PATH="/venv/bin:/usr/local/bin:$PATH"
RUN echo "export PATH=${PATH}" >> /root/.bashrc

ARG JUPYTERHUB_VERSION

RUN python --version \
    && pip install --quiet --upgrade pip \
    && if [ "$JUPYTERHUB_VERSION" != "" ]; then \
        pip install --quiet jupyterhub==${JUPYTERHUB_VERSION}; \
    fi \
    \
    && mkdir -p /data

ARG PYPI_PACKAGE
ARG PYPI_PACKAGE_VERSION

RUN pip install --quiet --upgrade pip \
    && pip install --quiet ${PYPI_PACKAGE}${PYPI_PACKAGE_VERSION:+==$PYPI_PACKAGE_VERSION} \
    && python -m spacy download en_core_web_sm \
    && npm cache clean --force \
    && jupyter lab clean \
    && pip cache purge

# RUN chown --quiet --recursive ${LAB_UID}.${LAB_GID} /venv

USER $LAB_USER

ENV HOME=/home/$LAB_USER

RUN mkdir -p $HOME/work

COPY --chown=$LAB_USER:users scripts $HOME/work/scripts
# COPY --chown=$LAB_USER:users data $HOME/work/data

ARG GITHUB_REPOSITORY_URL
ARG GITHUB_REPOSITORY_BRANCH
ARG GITHUB_REPOSITORY_INFO_URL
ARG GITHUB_ACCESS_TOKEN
ENV GITHUB_ACCESS_TOKEN=${GITHUB_ACCESS_TOKEN}

ADD  ${GITHUB_REPOSITORY_INFO_URL} /tmp/repo.info

RUN chmod +x $HOME/work/scripts/*.sh \
    && $HOME/work/scripts/update-notebooks.sh -b ${GITHUB_REPOSITORY_BRANCH} -r ${GITHUB_REPOSITORY_URL} notebooks resources __paths__.py

WORKDIR ${HOME}

CMD ["jupyterhub-singleuser"]

# CMD jupyter lab --ip=* --port=${LAB_PORT} --no-browser --allow-root
