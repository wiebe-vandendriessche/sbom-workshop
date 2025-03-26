# SBoM-Workshop

Welcome to the SBoM workshop! In this workshop we will guide you through generating and automating SBoMs! This workshop is designed for Ubuntu. The [install.md](install.md) file contains more info on how to set up the tools.

It would be best to [fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) this repository so you have you own copy. This is important when working with GitHub Actions. 

Once you have forked your repository, clone it to your Ubuntu machine.

When you have finished this workshop, feel free to give the tools a try on one of your own codebases!

If you have any question or are stuck anywhere, don't hesitate to ask us!

## Generate a Software Bill of Materials

A Software Bill of Materials is an essential part of producing or using software. While you could theoretically create one yourself, it is often better to have an automated tools generate one for you. The following section provides you with an overview of some of the different methods for generating SBoMs. Note that this is not an exhaustive list of options, there is a plethora of open-source tools that work with specific toolchains and we cannot possibly cover them all here.

>We have included formatted copies of each SBoM you will generate in the `SBoMs` folder.

### 1- Generate from an artifact

In this section you will generate an SBoM from artifacts. Depending on your development platform this can be a native binary or some other executable (E.g., Java JAR).

For this first example, we will build a native executable from a Rust project and attempt to create an SBoM from it.

Navigate to the `rust-code` subfolder of this project in your CLI. 

Build the Rust binary:
```bash
cargo build --release
```

Execute the binary to verify its functionality, it should print a random number:
```bash
./target/release/sbom_rust_binary
```
Congratulations, you now have some software you can ship to your customers. But now you want to comply with the CRA, so you need an SBoM.

There are many language specific tools out there but we like [`Syft`](https://github.com/anchore/syft) as it is easily detects various tools and languages.

Generate an SBoM with `Syft`:
```bash
syft sbom_rust_binary  -o spdx-json > rust_code_sbom.json
```

Take a look inside the SBoM. Is there any valuable information in there? Not really...

If you are familiar with the intricacies of building Rust code, you might already have an idea on what's happening here. Rust statically links the dependencies, for the non-experts: its just a self-contained binary blob now. So not ideal for extracting SBoMs... 

Let's try this in a different language, maybe Java will work?

Navigate to the `java-code` folder of this project in your CLI.

Build the Java project using `maven`.

```bash
mvn clean package
```

Run the JAR to make sure the build was successful, it should output a json representation of a Person object:

```bash
java -jar target/myapp-1.0-SNAPSHOT.jar
```

Let's try the SBoM again:

```bash
syft target/myapp-1.0-SNAPSHOT.jar -o spdx-json > sbom_java_code.json
```

Let's inspect the SBoM! This time (if you did everything right), a beautiful SBoM should appear (You might need to use a JSON beautifier to make it slightly more readable). While this document is usually machine processed, we've included a quick analysis of this SBoM here to teach you about its general structure and contents. Open the [SBoM analysis file](SBoM-analysis.md), return back here once you're through it.

This time we did actually manage to generate a decent SBoM from the executable. We used maven shade to create an uber-JAR which has all dependencies built-in so it's easy for Syft to extract them.

To conclude this section on generating SBoMs from artifacts we want to highlight that it can be a bit of a mixed bag. While it can be useful for your users that they can generate an SBoM themselves it does require a high degree of insight in the way your software is packaged. Optimizers or obfuscators could for example make it nearly impossible to generate an SBoM from an artifact so be mindful of this.

If your development process doesn't fit this generation method you can also generate an SBoM during the build process, which we will discuss in the next section.

### 2- Generate from source

As you can see, generating SBoMs from an executable can be a bit of a pain. Sometimes it works, sometimes it doesn't. A more popular option is to generate it while you are building your software. Most modern platforms depend on some package manager (Conan for C/C++, Maven for Java, pip for Python, Cargo for Rust,...). Giving an SBoM tools access to their specific 'manifest' files usually makes it more reliable as it can often obtain much more detailed information from the package sources. A disadvantage however is that these SBoMs often don't include the hash of the executable they relate to, as the artifact has often not been built yet.

In the following section, you will generate SBoMs from your project files using both general purpose tools and build specific ones.

Navigate back to the Rust project from earlier using the CLI. 

We've added the Cargo subcommand `sbom`, this will generate an SPDX SBoM similar to what we saw earlier with:

```bash
cargo sbom > rust_cargo_sbom.json
```

Feel free to look at the SBoM and even compare it to the Java one. You will find that it has a similar structure. It is however really not very 'human-readable' anymore, Rust crates pull in a lot of sub-dependencies. So while we only have a single dependency here: 'rand', our SBoM contains a lot more information. As your project grows this will only become more of a problem (but that is why automated analysis tools exist, more on them later).

Let's look at our Java example again. This example uses a more complex build environment with Maven. We can add an SPDX plugin to automatically generate the SBoM:

Add the plugin to your `pom.xml` file, under `build -> plugins`:
```xml
<plugin>
	<groupId>org.spdx</groupId>
	<artifactId>spdx-maven-plugin</artifactId>
	<version>0.6.5</version>
	<executions>
	  <execution>
	    <phase>package</phase>
	    <goals>
	      <goal>createSPDX</goal>
	    </goals>
	  </execution>
	</executions>
</plugin>
```

Build your package:
```bash
mvn clean package
```

This should output your SBoM at `target/site/com.example_myapp-1.0-SNAPSHOT.spdx.json`

If you compare the SBoMs you'll see a few differences. The Syft SBoM we generated from the JAR contains only internal dependency information with much richer vulnerability information, useful for an end-user but maybe not 100% complete either as your build toolchain might introduce vulnerabilities of its own. The Maven plugin does not contain as much information on vulnerability assessment but is richer on the dev environment info. Both should be adequate to 'comply' with regulations, but an organization releasing software should analyze their use for SBoMs further and decide based on that which one they release (you could also release both, but this might confuse users).

These sections gave you a small overview of different generation methods. As SBoMs are still quite new, we unfortunately cannot tell you exactly how te generate YOUR SBoMs. In general it comes down to analyzing your processes and testing different tools. Find the tools that provide the highest degree of insight in your entire process and work well with analysis tools (more on those later).

### 3- Generate in CI/CD

The following section will guide you through integrating your SBoM generation into a CI/CD pipeline. For this section we will use GitHub Actions as an example. You will build one of our internal Go projects and create an SBoM for it. This process can easily be translated to other common CI/CD and development platforms. We will use one of our internal project for this, which is called Feather.

If you have not done so, create a fork of this repository by clicking the 'fork' button at the top right of the page. You should now have your own version which you can edit freely.

Actions are described as a .yaml file under `.github/workflows/`, you can write them from scratch by just manually putting a yaml in this folder. Fortunately, GitHub Actions are quite mature so we're lucky and can start from a template.

In the repository, navigate to the `Actions` tab at the top of the page and click on `New Workflow`. Under `Suggested for this repository` you should find `Go`, click `Configure`.

Remove the `Test` job (nobody likes tests). 

Under `jobs:build` add the following permissions:

```yaml
permissions:
     contents: read
```

This permissions will allow the Action to pull the repository and read the code.

Next we need to edit the go setup action to cache our build (this will speed it up significantly). Add the cache and cache-dependency-path:

```yaml
- name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.20'
        cache: true
        cache-dependency-path: go-feather-action/go.sum 
```

This setup action will install Go in the runner and automatically set up caching to speed up your Go build.

Next we need to add the correct build command to build the binary:
```yaml
- name: Build
  working-directory: go-feather-action
  run: |
    go build -v -o feather-binary ./cmd/fledge
```

Create an artifact from the binary, available to anyone with access to the repository:
```yaml
- name: Upload Binary Artifact
  uses: actions/upload-artifact@v4
  with:
    name: feather-binary
    path: go-feather-action/feather-binary
```

Great, you've successfully built and published a go binary! Note that these artifacts will expire in a few months so you might want to add [a release](https://github.com/marketplace/actions/create-release) but this is not within the scope of this workshop. 

Let's now make an SBoM for your binary:

```yaml
- name: Install syft
  run: |
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

- name: Create SBOM
  run: syft go-feather-action/feather-binary -o spdx-json > syft-sbom.json

- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    name: syft-sbom.json
    path: syft-sbom.json
```

We will use Syft again as it works well for Go. Additionally, we define an artifact to release alongside our binary.

Commit this file to the main branch, the Action should start automatically. You can inspect the process by clicking on the Action's commit name under the `Action` tab. After a few minutes, it should be done and two artifacts should be available: the binary and the SBoM. You can inspect the process in more detail by clicking on the `build` task in the overview.

A major advantage of running this in a GitHub Action is that it is highly auditable. Your users can inspect the action and analyze the full build process (note that GitHub deletes detailed build logs after a few months, but users can still see what specific action was ran). They can also check exactly which commit was used to build the binary and generate the SBoM. However, once a user downloads the artifacts and they are separated this advantage is lost as neither the SBoM nor the binary contain any link to this build environment. The following section will introduce some ways to enhance trust in the SBoM and more confidently link it to the build environment.

#### Trusting software and the supply chain

In this section we will explore some methods to improve trust in the build process and the SBoM itself. We will use [Cosign](https://github.com/sigstore/cosign) to sign the SBoM. Cosign is well known for signing container images, but fortunately for us it can also sign arbitrary blobs such as our SBoM. In your own build environment you would probably use some private key stored as a secret. GitHub Actions however (GitLab and other also support this btw.), can use a keyless method for signing the blob.

Let's edit the GitHub action from earlier with keyless signing. In the Action yaml, make sure the following permissions are present under `jobs:build:permissions`

```yaml
permissions:
     contents: read
     id-token: write
```
GitHub can provide an OIDC token for an Action run, we are giving the Action permission to fetch it and use it for keyless signing.

Now  add the following:

```yaml
- name: Install Cosign
  uses: sigstore/cosign-installer@v3.8.1

- name: Sign SBOM
  env:
    COSIGN_EXPERIMENTAL: 1
  run: |
    cosign sign-blob --oidc-issuer https://token.actions.githubusercontent.com \
      --bundle syft-sbom.bundle \
      --yes \
      syft-sbom.json

- name: Upload artifacts
  uses: actions/upload-artifact@v4
    with:
      name: cosign-bundle
      path: syft-sbom.bundle

```

First we will install Cosign in the Action, we then sign using GitHub as an OIDC provider. Finally we upload Cosign's bundle as an artifact. We should now have a binary, an SBoM and a bundle as artifacts.

Cosign’s keyless signing uses GitHub’s OIDC integration to securely tie a signature to a specific GitHub Action run. During the workflow, Cosign generates an ephemeral key pair and requests a short-lived X.509 certificate from Fulcio, the Sigstore certificate authority. Fulcio authenticates the request using the OIDC token automatically issued by GitHub, and embeds the GitHub repository, workflow path, commit SHA, and actor identity into the certificate.

Cosign uses the ephemeral private key to sign the blob, and then submits the signature, certificate, and artifact digest to the Rekor transparency log. This creates a verifiable, immutable record that binds the artifact to a specific GitHub Action run. You can actually manually check this as well by extracting the certificate, where you will find the specific Action and the run identifier:

```bash
jq -r '.cert' <download location>/syft-sbom.bundle.json | base64 -d | openssl x509 -text -noout
```

Integrity is ensured because the signature is verifiable against the public key in the certificate, and the certificate is tied to a GitHub Action identity via OIDC. Provenance is established by the certificate contents, and transparency is enforced by the [Rekor log](https://github.com/sigstore/rekor) entry, which prevents undetected tampering or backdating.

Cosign can also verify all this for you so you don't have to manually check all signatures and certificates:

```bash
cosign verify-blob \
        --bundle <downloaded bundle file> \
        --certificate-identity "https://github.com/<your-gh-username>/sbom-workshop-go/.github/workflows/go.yml@refs/heads/main" \
        --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
        <downloaded SBoM file>
```

This command will check all signatures, verifying the integrity of the SBoM and checking that it is indeed tied to a specific GitHub Action and thus to a specific build environment. Note that this does not verify which specific run, but extra checks like this can be added using additional options. `cosign verify-blob --help` will give you an overview of these additional options.

We now have a build pipeline that creates the following:

- A Go binary
- A SBoM with a reference to the Go binary, containing information on dependencies.
- A Cosign Bundle, allowing users to verify the integrity of the SBoM and the way it was created.


## Using a Software Bill of Materials

While generating SBoMs is now commonplace and fairly mature, consuming them is not. The following section will cover some tools to analyze and use SBoMs but be mindful that this is very much a new thing. Standards for logging vulnerability information in SBoMs are not in place so many tools use their own, some are cross-compatible, some are not. If you have the option, try to stick to an 'ecosystem' where the generation and consumption tools are related.

### Detect secrurity vulnerabilities

An important part of an SBoM is vulnerability detection. All software contains vulnerabilities, most of them are just not known to anyone. When it comes to open-source software (which most libraries/crates/dependencies/... will be) they are often patched relatively quickly with a new release. This is great for shared libraries or packages that can be auto updated by the OS but not every platform has this option. 

Let's say your company uses a highly secure embedded device to generate authentication codes, which uses the `rand` Rust crate to generate random numbers. You purchased 300 devices in 2020 but over time some of them have been replaced with newer ones. You now have a bunch of devices with software that was compiled anywhere between 2020 and 2025. In 2020, a major vulnerability was detected in an older version of the crate embedded into your device. Without SBoMs, you would be completely in the dark on whether any of your devices are compromised so the only solution will likely be to trash them. With SBoMs for each version of the device, you can easily perform a scan of these SBoMs and replace devices as necessary in a targeted way.

The following section will introduce you to such scanning tools.

The parent company behind Syft, Anchore (which we used earlier to generate our SBoMs) also created a tool to detect vulnerabilities called [Grype](https://github.com/anchore/grype). Full disclosure: their tools are free and open source but their business model is to get you to use their SaaS platform to manage and automate everything related to SBoMs. Still, their tools work well and are easy to use.

Like Syft, Grype was designed for container vulnerability management but now also supports SBoMs.

Use Grype on the SBoM we generated using the GitHub Action:
```bash
grype sbom:./syft-sbom.json
```

As you can see, feather contains a number of vulnerable dependencies that should probably be updated.

The output you get is very much human readable but you can use the `-o` option to specify a different output format if you wish to automate any of this.

### Detect License conflicts

License detection based on an SBoM is quite a bit harder than vulnerability analysis. Many tools don't focus on the license side of things and struggle generating an SBoM with correct licensing information. If you go through the SBoMs we just generated you will not find a lot of license information.

The idea behind SBoMs also significantly changes when it comes to licenses instead of vulnerabilities. A license is a legal document, if a supplier provides you with some software and tells you that it comes with a certain license it is their responsibility to make sure there are no conflicts. So SBoMs for licenses are more of an internal thing to make sure you don't *ship* software with such conflicting licenses whereas vulnerability detection is often done by the party receiving or using the software.

It's honestly not easy to recommend any tools for this purpose. There are some well known enterprise solutions (E.g.,FOSSA) and some others that I never got to test because they are just a huge [P.I.T.A.](https://www.urbandictionary.com/define.php?term=P.I.T.A.) to install (E.g., ScanCode). At the risk of sounding like a broken record, Anchore saves us once again (I promise this is not a sponsored workshop, but their stuff usually does just work). Their [Grant](https://github.com/anchore/grant) tool is the easiest and works quite well.

There are a few caveats though. We've mentioned that the SBoM license landscape is highly fractured and immature. Most packages uploaded to repositories do not adhere to the [SPDX license identifiers](https://spdx.org/licenses/). Most SBoM tools will look for those identifiers and thus fail to detect licenses. An example is the gnu crypto libary, it comes with a GPL license which imposes some restrictions, however Syft catalogues it as a custom license and Grant does not catch those. We will show you how to use the tool anyways, but be warned that their output should probably be manually verified.

We will run the analysis on the SBoM you created earlier from the Java source using the Maven plugin (`java-code/target/site/com.example_myapp-1.0-SNAPSHOT.spdx.json`).

```bash
# Note: we include the `--non-spdx` so it will also fail on non-SPDX licenses, this helps with the caveat we outlined above
grant check <SBoM loation> --non-spdx
```

By default, Grant will deny all licenses. We can however define a custom policy, or use a pre-defined one. If you want to be open-source friendly you could use `--osi-approved` to comply with the Open Source Initiative's definition. For some companies it might be imperative not to include strong copy-left licenses and that may require writing a custom policy. Our Java JAR contains a package with the CPL-1.0 license, a very old and deprecated license. Let's write a policy to deny any CPL license:

```yaml
#grant.yaml
config: "grant.yaml"
format: table # table, json
show-packages: true # show the packages which contain the licenses --show-packages
non-spdx: true # also list licenses that could not be matched to an SPDX identifier --non-spdx
osi-approved: false # highlight licenses that are not OSI approved --osi-approved
rules:
    - pattern: "*cpl*"
      name: "deny-cpl"
      mode: "deny"
      reason: "CPL licenses are not allowed per company policy"
```

Store this file as `grant.yaml`. Let's execute our license check:

```bash
grant check java-code/target/site/com.example_myapp-1.0-SNAPSHOT.spdx.json --config grant.yaml
```

Huzaah! Our license issue is detected! You can customize these policies: add more rules, add exceptions,... More info [here](https://github.com/anchore/grant?tab=readme-ov-file#usage).


## Final words

At this point, you've seen what it takes to generate, consume, and verify an SBoM. You've dealt with binaries that tell you nothing, build tools that tell you too much, and CI pipelines that can produce signed artifacts with some minimal setup. You've also seen that SBoMs are not magic. They're only as useful as the process and tooling behind them.

There's still no one-size-fits-all. Different languages, packaging methods, and deployment targets all need slightly different approaches. The ecosystem is growing fast but still fragmented. You'll need to test and adapt based on your own environment. Trust in a tool should follow from how well it integrates into your process, not just its marketing or popularity.

SBoMs are not just about compliance. They're a way to get visibility into what you ship, and they make security and maintenance work a lot less painful in the long run. If you treat them as a core part of your release pipeline, not an afterthought, they will pay off.

**That's it.** If you got this far and are still not tired of the word SBoM, you could now try these tools on one of your own projects or even create and release a signed SBoM for one of your own pipelines? Maybe even try to detect some vulnerabilities of license issues?


**All the tools used in this workshop:**

Syft: https://github.com/anchore/syft

Grype: https://github.com/anchore/grype

Grant: https://github.com/anchore/grant

Maven SPDX plugin: https://github.com/spdx/spdx-maven-plugin

cargo sbom: https://github.com/psastras/sbom-rs

Cosign: https://github.com/sigstore/cosign
