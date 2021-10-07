### Ansible Assignment

- Provision one bastion, one dev, one prod using terraform
- Use Ansible to install dependencies like ruby, nodejs using galaxy roles
- Use Ansible to deploy a toy rails application using passenger and nginx as web and app server.
- Add a simple DB migration.  (till this point things could be tested with vagrant for speeding up)
- Then add an simple RDS instance configure application to use RDS and  run migration.
- At that point introduce one more server. This time all the provisioning should be happening seamlessly.
- Do rolling deployment and fail-over using ansible.

#### Pre-requisites
- Ansible
- Vagrant (if needed to run locally instead of cloud)


#### Setup
```bash
vagrant up
make app-setup
make app-deploy
```