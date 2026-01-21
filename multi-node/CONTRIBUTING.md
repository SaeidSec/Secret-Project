# 🤝 Contributing to Enterprise-Grade Wazuh SIEM

Thank you for your interest in contributing! This project aims to provide a production-ready Wazuh deployment for the security community.

## How to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Use the bug report template** when creating new issues
3. **Include details:**
   - Docker version
   - Docker Compose version
   - OS and version
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs

### Suggesting Enhancements

1. **Open an issue** with the enhancement label
2. **Describe the use case** and benefits
3. **Provide examples** if applicable
4. **Consider backward compatibility**

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/AmazingFeature
   ```

3. **Make your changes:**
   - Follow existing code style
   - Update documentation
   - Add comments where needed
   - Test thoroughly

4. **Commit with clear messages:**
   ```bash
   git commit -m "Add: New monitoring dashboard for XYZ"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/AmazingFeature
   ```

6. **Open a Pull Request:**
   - Describe changes clearly
   - Reference related issues
   - Include testing steps

## Development Guidelines

### Code Style

- **YAML files:** 2-space indentation
- **Shell scripts:** Use shellcheck
- **Documentation:** Markdown with proper formatting
- **Comments:** Explain "why", not "what"

### Testing

Before submitting a PR:

```bash
# Test deployment
cd multi-node
docker compose down -v
docker compose up -d

# Verify all services
docker compose ps

# Check logs for errors
docker compose logs | grep -i error

# Test HA failover
docker stop nginx-lb-1 keepalived-1
# Verify services still accessible

# Test agent enrollment
# Deploy test agent and verify connectivity
```

### Documentation

- Update README.md for new features
- Add configuration examples
- Include troubleshooting steps
- Update architecture diagrams if needed

## Project Structure

```
.
├── multi-node/
│   ├── config/
│   │   ├── nginx/          # Nginx load balancer configs
│   │   ├── keepalived/     # HA configuration
│   │   ├── zabbix/         # Monitoring configs
│   │   ├── grafana/        # Dashboards and datasources
│   │   └── wazuh_*/        # Wazuh component configs
│   ├── docker-compose.yml  # Main deployment file
│   └── generate-indexer-certs.yml
├── README.md
├── DEPLOYMENT_GUIDE.md
├── CERTIFICATE_GENERATION.md
└── CONTRIBUTING.md
```

## Areas for Contribution

### High Priority
- [ ] Kubernetes deployment manifests
- [ ] Terraform/Ansible automation
- [ ] Additional Grafana dashboards
- [ ] Performance optimization guides
- [ ] Security hardening scripts

### Medium Priority
- [ ] Multi-region deployment guide
- [ ] Backup/restore automation
- [ ] Custom Wazuh rules and decoders
- [ ] Integration guides (SOAR, ticketing systems)
- [ ] Advanced threat hunting queries

### Documentation
- [ ] Video tutorials
- [ ] Architecture deep-dives
- [ ] Troubleshooting guides
- [ ] Best practices documentation
- [ ] Translations

## Community Guidelines

### Be Respectful
- Treat everyone with respect
- Welcome newcomers
- Provide constructive feedback
- Focus on the issue, not the person

### Be Collaborative
- Share knowledge
- Help others learn
- Review pull requests
- Participate in discussions

### Be Professional
- Follow the code of conduct
- Keep discussions on-topic
- Respect different viewpoints
- Maintain a positive environment

## Getting Help

- **Questions:** Open a GitHub Discussion
- **Bugs:** Create an Issue
- **Security:** Email security concerns privately
- **Wazuh Specific:** Check [Wazuh documentation](https://documentation.wazuh.com/)

## Recognition

Contributors will be:
- Listed in the project README
- Mentioned in release notes
- Credited in documentation

## License

By contributing, you agree that your contributions will be licensed under the GNU General Public License v2.0.

---

**Thank you for making this project better! 🎉**
