# Static Site

A containerized static website served by [Caddy](https://caddyserver.com/), deployed as a Kubernetes Pod with health probes and automated CI/CD through Jenkins.

## Repository Structure

```
static-site/
├── Caddyfile              # Caddy web server configuration
├── Dockerfile             # Multi-platform container image definition
├── Jenkinsfile            # CI/CD pipeline for building and publishing images
├── Jenkinsfile.pr         # PR status check for conventional commit validation
├── html/
│   └── index.html         # Static HTML page with team details
├── k8s/
│   ├── configmap.yaml     # Application configuration
│   ├── secret.yaml        # DockerHub image pull secret
│   └── pod.yaml           # Kubernetes Pod definition with health probes
├── .gitignore
└── README.md
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) installed
- Access to a private DockerHub repository
- Jenkins server with the Conventional Commits plugin

## Local Development

### Build the Docker Image

```bash
docker build -t static-site .
```

### Run Locally

```bash
docker run -p 8080:8080 static-site
```

Visit `http://localhost:8080` to view the site and `http://localhost:8080/healthz` for the health check endpoint.

## Deploying to Kubernetes

### 1. Create a kind Cluster

```bash
kind create cluster --name dev
```

### 2. Create DockerHub Image Pull Secret

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<DOCKERHUB_USERNAME> \
  --docker-password=<DOCKERHUB_TOKEN> \
  --docker-email=<DOCKERHUB_EMAIL>
```

### 3. Apply Kubernetes Manifests

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pod.yaml
```

### 4. Verify Deployment

```bash
kubectl get pods
kubectl describe pod static-site
```

### 5. Access the Application

```bash
kubectl port-forward pod/static-site 8080:8080
```

Visit `http://localhost:8080` in your browser.

### 6. Cleanup

```bash
kubectl delete -f k8s/pod.yaml
kubectl delete -f k8s/configmap.yaml
kubectl delete secret dockerhub-secret
kind delete cluster --name dev
```

## Health Probes

The application exposes the following health check endpoints:

| Probe     | Endpoint   | Purpose                                              |
|-----------|------------|------------------------------------------------------|
| Startup   | `/healthz` | Ensures the container has started successfully       |
| Readiness | `/readyz`  | Indicates the application is ready to receive traffic|
| Liveness  | `/healthz` | Detects if the application has crashed or is hung    |

## CI/CD Pipeline

### Overview

The CI/CD pipeline is powered by Jenkins and triggered via GitHub webhooks.

### Build Pipeline (`Jenkinsfile`)

Triggered on push/merge to `main`:

1. **Checkout** — Clones the repository with full history and tags
2. **Determine Next Version** — Uses the Conventional Commits plugin to calculate the next semantic version based on commit messages since the last tag
3. **Setup Buildx** — Configures Docker Buildx for multi-platform builds
4. **Login to DockerHub** — Authenticates using Jenkins credentials
5. **Build & Push** — Builds multi-platform images (`linux/amd64`, `linux/arm64`) and pushes to DockerHub
6. **Tag Release** — Tags the commit with the new version and pushes the tag to GitHub

### PR Status Check (`Jenkinsfile.pr`)

Triggered on pull request creation/update:

1. **Checkout** — Clones the PR branch
2. **Validate Conventional Commits** — Checks all commit messages in the PR against the Conventional Commits specification. Invalid commits block the merge.

### Conventional Commits

All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(optional scope): description
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

Examples:

```
feat: add health check endpoint
fix(caddy): update port configuration
docs: update README with deployment steps
chore: update dependencies
```

### Semantic Versioning

The pipeline automatically determines the next version based on commit types:

| Commit Type        | Version Bump | Example         |
|--------------------|--------------|-----------------|
| `fix:`             | Patch        | 1.0.0 → 1.0.1  |
| `feat:`            | Minor        | 1.0.0 → 1.1.0  |
| `feat!:` / `BREAKING CHANGE` | Major | 1.0.0 → 2.0.0 |

### Setting Up Jenkins

1. Ensure the following plugins are installed in Jenkins: `conventional-commits`, `job-dsl`, `github-branch-source`, `docker-workflow`
2. Configure credentials in Jenkins:
   - `dockerhub-credentials` — Username with password (DockerHub username + access token)
   - `github-credentials` — Username with password (GitHub username + PAT with `repo` and `admin:repo_hook` scopes)
3. Set up a webhook in the GitHub repository:
   - Payload URL: `https://jenkins.yourdomain.tld/github-webhook/`
   - Content type: `application/json`
   - Events: Pushes, Pull requests
