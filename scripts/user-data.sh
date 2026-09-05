#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting EC2 User Data script..."

# Install NGINX
echo "Installing NGINX..."
dnf install -y nginx

# Copy the website from S3
echo "Copying website from S3..."

if ! aws s3 sync s3://my-s3-website2626 /usr/share/nginx/html; then
    echo "ERROR: Failed to copy website from S3."
    echo "Check the EC2 IAM role, S3 bucket name, and S3 VPC endpoint."
    exit 1
fi

# Get the instance Availability Zone using IMDSv2
echo "Getting Availability Zone..."

TOKEN=$(curl -sS -f -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

AZ=$(curl -sS -f \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/placement/availability-zone")

echo "Availability Zone: $AZ"

# Create a small server-identification page
cat > /usr/share/nginx/html/instance-info.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>EC2 Instance Information</title>
</head>
<body>
    <h1>EC2 Web Server</h1>
    <p>Availability Zone: $AZ</p>
</body>
</html>
EOF

# Enable and start NGINX
echo "Starting NGINX..."
systemctl enable nginx
systemctl start nginx

echo "User Data script completed successfully."
