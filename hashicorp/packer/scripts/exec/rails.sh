###
# Create Minimal Project
###

## Prepare Install Directory and chown to Ubuntu user
#sudo mkdir -p /var/www/ && sudo chown ubuntu:ubuntu -R /var/www/

# Create new minimal project as Ubuntu user
rails new --minimal -d postgresql /var/www/project
