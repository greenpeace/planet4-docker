#!/usr/bin/env bash
set -e

[[ "${INSTALL_APM_AGENT}" = "true" ]] || exit 0

wget --retry-connrefused --waitretry=1 -t 5 "https://github.com/elastic/apm-agent-php/releases/download/v${APM_AGENT_PHP_VERSION}/apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb.sha512"
wget --retry-connrefused --waitretry=1 -t 5 "https://github.com/elastic/apm-agent-php/releases/download/v${APM_AGENT_PHP_VERSION}/apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb"

sha512sum -c "apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb.sha512"

dpkg -i "apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb"

rm -f "apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb" "apm-agent-php_${APM_AGENT_PHP_VERSION}_all.deb.sha512"
