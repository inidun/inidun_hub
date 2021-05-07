# JupyterHub configuration

import os
import sys
import oauthenticator

network_name = os.environ['HUB_NETWORK_NAME']
spawn_cmd = os.environ.get('DOCKER_SPAWN_CMD', "start-singleuser.sh")
config_dir = os.environ.get('HUB_CONFIG_FOLDER', '/etc/jupyterhub')
project_name =os.environ.get('PROJECT_NAME', 'public')
data_dir = os.environ.get('HUB_HOST_VOLUME_FOLDER', '/data')

notebook_dir ='/home/jovyan/work'

project_data_dir = os.path.join(data_dir, project_name)

def read_userlist():
    allowed_users, admin = set(), set()
    filename = os.path.join(config_dir, "userlist")
    assert os.path.isfile(filename), "userlist expected at {}".format(filename)
    with open(filename, "r") as fi:
        lines = [
            x.split() for x in [ y.strip() for y in fi.readlines() ]
                if len(x) > 0 and not x.startswith('#')
        ]
    allowed_users = set([ x[0] for x in lines ])
    admin = set([ x[0] for x in lines if len(x) > 1 and x[1] == "admin" ])
    return allowed_users, admin

c = get_config()

c.JupyterHub.services = [
    {
        'name': 'idle-culler',
        'admin': True,
        'command': [
            sys.executable,
            '-m', 'jupyterhub_idle_culler',
            '--timeout=3600'
        ],
    }
]

c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'
c.JupyterHub.admin_access = True
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_connect_ip = os.environ['HUB_IP']
c.JupyterHub.authenticator_class = oauthenticator.github.GitHubOAuthenticator
c.JupyterHub.cookie_secret_file = '/srv/jupyterhub/jupyterhub_cookie_secret'

c.GitHubOAuthenticator.oauth_callback_url = os.environ['OAUTH_CALLBACK_URL']
c.GitHubOAuthenticator.client_id = os.environ['OAUTH_CLIENT_ID']
c.GitHubOAuthenticator.client_secret = os.environ['OAUTH_CLIENT_SECRET']

c.Authenticator.allowed_users, c.Authenticator.admin_users = read_userlist()

c.DockerSpawner.image = os.environ['DOCKER_JUPYTER_CONTAINER']
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name
c.DockerSpawner.notebook_dir = notebook_dir

c.DockerSpawner.volumes = {
    'jupyterhub-' + project_name + '-user-{username}': notebook_dir,
    project_data_dir: {
        "bind": project_data_dir,
        "mode": "rw"
    }
}

c.DockerSpawner.remove_containers = True
c.DockerSpawner.host_ip = "0.0.0.0"
c.DockerSpawner.name_template = "jupyterhub-" + project_name + "-{username}"

c.Spawner.default_url = '/lab'
c.Spawner.mem_limit = '3G'
c.Spawner.notebook_dir = notebook_dir

# Debug settimgs
c.JupyterHub.debug_proxy = True
c.DockerSpawner.debug = True
c.JupyterHub.log_level = 10
c.Spawner.cmd = ['jupyterhub-singleuser', '--debug']
c.Authenticator.auto_login = False
