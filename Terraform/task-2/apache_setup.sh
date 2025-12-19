#!/bin/bash
# 1. Update the system
dnf update -y

# 2. Install Apache (httpd) and AWS CLI
dnf install -y httpd awscli

# 3. Start and enable Apache service
systemctl start httpd
systemctl enable httpd

# 4. Attempt to fetch HTML from S3 if bucket name provided
if [ -n "${s3_bucket_name}" ]; then
    aws s3 cp s3://${s3_bucket_name}/NTI_info.html /var/www/html/index.html --region ${region} || true
fi

# 5. Create the NTI DevSecOps HTML page (fallback if S3 fetch fails)
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NTI DevSecOps Group - Egypt</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8f9fa; color: #212529; margin: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
        .card { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); text-align: center; max-width: 500px; border-left: 10px solid #732a24; }
        h1 { color: #732a24; margin-top: 0; font-size: 2em; }
        h2 { color: #555; font-weight: 400; font-size: 1.2em; margin-bottom: 20px; }
        .divider { height: 1px; background: #eee; margin: 20px 0; }
        p { line-height: 1.6; color: #666; }
        .footer { margin-top: 30px; font-size: 0.85em; color: #aaa; text-transform: uppercase; letter-spacing: 1px; }
        .btn { display: inline-block; margin-top: 15px; padding: 10px 20px; background-color: #732a24; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h1>NTI Egypt</h1>
        <h2>DevSecOps Professional Group</h2>
        <div class="divider"></div>
        <p>This server was successfully provisioned using <strong>Terraform User Data</strong> and is currently running <strong>Apache (httpd)</strong> on Amazon Linux 2023.</p>
        <p>The National Telecommunication Institute is leading the way in Egypt for secure, automated infrastructure training.</p>
        <a href="#" class="btn">Learn More about DevSecOps</a>
        <div class="footer">
            Managed by Infrastructure as Code (IaC)
        </div>
    </div>
</body>
</html>
EOF

# 6. Set correct permissions for the web directory
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
