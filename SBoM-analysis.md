# Understanding the SBoM

This document outlines the SBoM generated from the `myapp` project in this workshop. You can follow along with your SBoM but details such as hashes or timestamps will likely differ. We also have an example available [here](SBoMs/sbom_java_code.json).

## 1. File Format and Overall Structure  
The document follows the [SPDX 2.3](https://spdx.github.io/spdx-spec/v2.3/) format, a standard for Software Bill of Materials (SBoM) data. It begins with metadata describing:  
- **Creator**: `Anchore, Inc`, using `syft-1.20.0`  
- **Creation date**: `2025-03-26T20:15:25Z` (yours will be different)
- **License for the SBoM**: `CC0-1.0` (public domain)  

## 2. Top-Level Document  
- The SBoM refers to **`myapp-1.0-SNAPSHOT.jar`** as the described artifact.  
- A unique `documentNamespace` prevents conflicts with other SPDX documents.  
- The top-level SPDXID is `SPDXRef-DOCUMENT`, representing the document itself.

## 3. Packages  
The JSON lists **four** packages.

Each package also has external references to:
- **CPEs**: Useful for matching known vulnerabilities  
- **purl (Package URL)**: Helps with resolution in package managers like Maven  

### **Gson**
Dependency for JSON processing.

- **Name**: `gson`
- **Version**: `2.10.1`
- **Declared License**: `Apache-2.0`
- **External Refs**: CPEs and a purl for Maven  
- **Usage**: Direct dependency of `myapp`  

### **JSON**  
Another JSON libary

- **Name**: `json`
- **Version**: `20210307`
- **Declared License**: `LicenseRef-The-JSON-License` (Note: this is a non-standard license)
- **External Refs**: CPEs (including `org.json`, `sonatype`, etc.) and purl  
- **Usage**: Also a direct dependency of `myapp`  

### **Myapp**
The core application.

- **Name**: `myapp`
- **Version**: `1.0-SNAPSHOT`
- **Declared License**: `LicenseRef-Apache-License--Version-2.0`
- **External Refs**: Multiple CPEs and purl
- **Checksums**: SHA1 provided  
- **Usage**: Main application artifact  

### **JAR File (`myapp-1.0-SNAPSHOT.jar`)**
The bundled output.

- **Checksum (SHA256)**: `0087fdc0acceb9e78a8b49ad946249be56156ec2b9243592b37e7b4a38a3b5f9`  
- **Marked as a primary file (SPDX `FILE`)**  
- **License**: `NOASSERTION` (The JAR file itself has no license)
- **Contains**: `myapp`, `gson`, `json`  

## 4. Files  
The SBoM tracks a single application file:

- **Name**: `myapp-1.0-SNAPSHOT.jar`
- **Type**: `APPLICATION`  
- **Checksums**: Both SHA1 and SHA256  
- **License**: `NOASSERTION` (no license specified inside the JAR)  

## 5. Relationships  
Relationships define how components relate to one another.

- **`DEPENDENCY_OF`**  
  - `gson` → `myapp`  
  - `json` → `myapp`

- **`CONTAINS`**  
  The JAR contains:  
  - `gson`  
  - `json`
  - `myapp`  

- **`OTHER / evident-by`**  
  The presence of `gson`, `json`, and `myapp` is indicated by the existence of the JAR file. This is **Syft-specific**, not native to SPDX.

- **`DESCRIBES`**  
  The top-level document describes the JAR.

## Conclusion

The updated SBoM **describes** `myapp-1.0-SNAPSHOT.jar`, which contains:  
- The `myapp` application (under Apache License 2.0)  
- The `gson` library (`2.10.1`)  
- The `json` library (`20210307`) under a custom JSON license  

You can now return to the main [README](README.md)!
