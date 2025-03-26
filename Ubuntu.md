# Install tools on your own Ubuntu

These instruction will help you install the tools on Ubuntu. This should work on a VM, WSL, bare metal,...

Update your apt repositories and install package updates:

```bash
sudo apt update && sudo apt upgrade -y
```

Install git, curl and build-essential (required for installing tools):

```bash
sudo apt install git curl build-essential -y
```

Install Rust:

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"
```

Install cargo-sbom. If the cargo command is not found, restart your terminal.

```bash
cargo install cargo-sbom
```

Install Anchore tools (Syft, Grype, Grant):

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grant/main/install.sh | sudo sh -s -- -b /usr/local/bin
```

Install Maven for the Java project:

```bash
sudo apt install maven
```

Install Cosign to verify SBoM signatures:

**for x86:**
```bash
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

```

**for arm64:**
```bash
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-arm64"
sudo mv cosign-linux-arm64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

```
