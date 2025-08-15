#!/bin/bash

# Update system
apt-get update -y

# Install Apache web server
apt-get install -y apache2

# Start and enable Apache
systemctl start apache2
systemctl enable apache2

# Create a simple index page
echo "Hello from Terraform on Azure" > /var/www/html/index.html

# Install Azure CLI for storage upload
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Create log upload script
cat > /etc/cron.daily/apache-log-azure << 'CRON'
#!/bin/bash
DATE=$(date +%Y-%m-%d)
STORAGE_ACCOUNT="${storage_account_name}"
CONTAINER="${container_name}"

# Login using managed identity
az login --identity

# Upload access log to Azure Storage
if [ -f /var/log/apache2/access.log ]; then
    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER" \
        --name "$DATE/access.log" \
        --file /var/log/apache2/access.log \
        --auth-mode login
fi
CRON

chmod +x /etc/cron.daily/apache-log-azure

# Set proper permissions
chown www-data:www-data /var/www/html/index.html
chmod 644 /var/www/html/index.html