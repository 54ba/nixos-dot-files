#!/bin/bash
# Security Configuration Script
# Additional security tools and monitoring setup

echo "Setting up additional security monitoring and tools..."

# Check firewall status (NixOS firewall is configured in configuration.nix)
echo "Current firewall status:"
sudo iptables -L -n -v

# Setup ClamAV database update
echo "Updating ClamAV virus definitions..."
sudo systemctl start clamav-freshclam
sudo systemctl enable clamav-freshclam

# Enable and start security services
echo "Starting security services..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Update rkhunter database
echo "Updating rkhunter database..."
sudo rkhunter --update || echo "rkhunter update completed with warnings (normal)"

# Run initial security scan (optional)
read -p "Run initial security scan? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running security scan..."
    sudo systemctl start security-scan
    echo "Security scan started. Check logs with: journalctl -u security-scan -f"
fi

# Check fail2ban status
echo "Fail2ban status:"
sudo fail2ban-client status

echo ""
echo "Security recommendations:"
echo "1. Review the rules above and adjust for your specific needs"
echo "2. Monitor UFW logs with: sudo tail -f /var/log/ufw.log"
echo "3. Check UFW status anytime with: sudo ufw status"
echo "4. Add specific application rules as needed with: sudo ufw allow <app>"
echo "5. Consider using 'sudo ufw app list' to see available application profiles"

