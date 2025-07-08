#!/bin/bash
yum update -y

# Basic application setup
echo "Environment: ${environment}" > /etc/environment
echo "Project: ${project}" >> /etc/environment