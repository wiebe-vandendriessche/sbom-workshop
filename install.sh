#!/bin/bash

# This script install all tools used in this workshop on Ubuntu

# Install apt packages
# git: download repository
# curl: download install files 
# build-essential: needed to build cargo-sbom
sudo apt update && sudo apt upgrade -y
sudo apt install git curl build-essential -y

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"

# Install cargo-sbom
cargo install cargo-sbom

# Install Anchore Syft and Grype and Grant
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grant/main/install.sh | sudo sh -s -- -b /usr/local/bin

# Install Maven Java
sudo apt install maven

# Install Cosign
# amd64
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# arm64
#curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-arm64"
#sudo mv cosign-linux-arm64 /usr/local/bin/cosign

sudo chmod +x /usr/local/bin/cosign
