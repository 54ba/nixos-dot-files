{ pkgs }:

with pkgs; [
  # Programming languages and runtimes
  nodejs  # Use latest stable nodejs
  nodePackages.npm
  nodePackages.yarn
  nodePackages.pnpm
  deno
  bun
  
  python311
  python311Packages.pip
  python311Packages.virtualenv
  pipenv  # pipenv is a separate package
  poetry
  
  rustup
  cargo
  
  go
  
  zig
  
  php82
  php82Packages.composer
  
  ruby
  bundler
  
  lua
  luarocks
  
  # Java development
  openjdk17
  maven
  gradle
  
  # .NET development
  dotnet-sdk_8  # Updated to newer LTS version
  
  # Database tools
  mongodb-compass
  postgresql
  sqlite
  redis
  
  # Container and orchestration tools
  docker
  docker-compose
  podman
  buildah
  
  kubectl
  kubernetes-helm
  minikube
  k9s
  stern
  kubectx
  
  # Cloud tools
  awscli2
  azure-cli
  google-cloud-sdk
  
  # Infrastructure as Code
  terraform
  terragrunt
  ansible
  
  # Version control
  gh  # GitHub CLI
  gitlab-runner
  
  # Code editors and IDEs
  vscode
  code-server
  
  # Build tools
  cmake
  ninja
  meson
  
  # Debugging and profiling
  gdb
  valgrind
  strace
  ltrace
  
  # Network debugging
  wireshark
  tcpdump
  
  # API testing
  postman
  insomnia
  
  # Documentation
  pandoc
  graphviz
  
  # Virtualization
  qemu
  libvirt
  vagrant
]

