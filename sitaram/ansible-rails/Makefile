GALAXY_ROLE_DIR=galaxy-roles
requirements:
	ansible-galaxy install --roles-path $(GALAXY_ROLE_DIR) -r requirements.yml

app-setup: requirements
	ansible-playbook  -i inventories/production/hosts app-setup.yml

app-deploy: requirements
	ansible-playbook  -i inventories/production/hosts app-deploy.yml