#!/usr/bin/env bash
# Failsafe to exit on errors
set -e

echo "Provisioning SSH for PVE deployment..."

# Install nano quietly so it doesn't hang the deployment
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install nano -y -qq

SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwXnO6Jpbin9uDkrNWAxUkxhJUls0WIvHxgc7GcrClh2RTOVNL6TwODTO1uGSWePRiQQuCVosryndZiW80AHuTdgoIunEcYfLyQSnnL3dIQt70h8drlQ1CNLNJL7KAHmRG4Meor8tj4yUIzDtp0wUebtPjpvxFFkdzmG1wfbJeXgOTc8oMGwhan9LVMwN7XmjhMZ092F6i7jxhm6J89GIKTZ1gt5kkS/yWKTPNT+KtX1OtTUq+8a+iEkx4RMQSCuAbjpXQa8pD5oCbWF7RSHmqR7fiHLzpmXKY2FLC3q4y8EQT7IPdQn3LdhjsQa76bJBg5wz04wfzbLsFiKBWV49TuZDbTlT/4+Ly4DkDunt3BYrjE26lapEB84ahyFuYsj37ppnzC2gIMRSke9LQuk4XA/6B3igmKJ/gF66Z40CR9DVlA7ZYhY3wul4CR011kDqnGfKdgXMjGsOonvFRVWSDM98F04hnDV4h39R72drzD7mA3Mbruwe/PXKWxQ+ClttZ2kjKfXrFQzmR7jEIkg9aBLv7W8B1jBAPfPvz4QnzNaMkqu0gl7pUuIrqFNSMv1sfK8glfV4PNBI9ENTnBfCxd0yeLvm/PuxX0w562H/wIiwC80Y48Y4Ka7B7ByV28W+wW3tnP75J/aNBmsmSmPinPHYDaA2fW4Z/oFoqr6Ke7w=="

# Root Setup
mkdir -p /root/.ssh
echo "$SSH_KEY" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Normal User Setup (if deployed via a sudo user)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    mkdir -p "$USER_HOME/.ssh"
    echo "$SSH_KEY" > "$USER_HOME/.ssh/authorized_keys"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.ssh"
fi

# Overwrite SSHD Config cleanly
cat <<EOF > /etc/ssh/sshd_config
ChallengeResponseAuthentication no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PrintMotd no

PermitRootLogin yes
X11Forwarding yes
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Restart service (handles both Debian/Ubuntu and RHEL/Rocky naming)
systemctl restart ssh || systemctl restart sshd



echo "Done. SSH is ready to use."
