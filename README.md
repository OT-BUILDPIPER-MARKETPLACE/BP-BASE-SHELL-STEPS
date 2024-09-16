## Overview

This repository contains all the essential shell functions used across multiple repositories. It serves as a centralized collection of functions that can be shared and reused via Git submodules across various projects. The functions cover various operations such as AWS interactions, Docker management, file handling, logging, Git operations, and more.

### Directory Structure
```
.
├── aws-functions.sh          # Functions related to AWS operations
├── data/
│   ├── di.template           # Data template for DI (Dependency Injection)
│   └── mi.template           # Data template for MI (Microservices Integration)
├── di-functions.sh           # Functions for Dependency Injection handling
├── docker-functions.sh       # Functions for managing Docker operations
├── file-functions.sh         # Functions for file handling and manipulation
├── functions.sh              # Main entry point for shell function utilities
├── git-functions.sh          # Functions for Git operations and integrations
├── log-functions.sh          # Functions for logging and debug management
├── mi-functions.sh           # Functions for Microservices Integration handling
├── README.md                 # This documentation file
└── str-functions.sh          # Functions for string manipulation
```

### Purpose
This directory contains shell scripts and functions that are widely utilized in various repositories. It is primarily used as a Git submodule in different projects, providing a shared set of utilities to streamline processes and ensure consistency across environments.

### Maintenance
This branch (`v1.0`) is actively maintained by **Mukul Joshi** (GitHub ID: `mukulmj`), who manages the repository on behalf of **Opstree**. It is currently used for **Airtel** projects and may be updated periodically to support the project's evolving needs.

