FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    gcc \
    g++ \
    gfortran \
    git \
    wget \
    time \
    python3 \
    python3-pip \
    default-jdk \
    golang \
    bc \
    xz-utils \
    bsdmainutils \
    libc6 \
    zlib1g \
    libstdc++6 \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    unzip \
    ruby \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for dynamic loader (helps with OrbStack compatibility)
RUN mkdir -p /lib64 && \
    ln -s /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 || true

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Julia using the official installation script
RUN curl -fsSL https://install.julialang.org | sh -s -- -y
ENV PATH="/root/.juliaup/bin:${PATH}"

# Install Zig - fixed installation
RUN mkdir -p /opt/zig && \
    wget -O /tmp/zig.tar.xz https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz && \
    tar -xf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 && \
    rm /tmp/zig.tar.xz && \
    ln -s /opt/zig/zig /usr/local/bin/zig

# Install Node.js with LTS version for better stability
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    # Verify Node installation
    node --version && \
    npm --version

# Install TypeScript and ts-node with specific versions for compatibility
RUN npm install -g typescript@4.9.5 ts-node@10.9.1 @types/node && \
    npm list -g --depth=0 && \
    # Create symlinks to ensure ts-node is in path
    ln -sf /usr/lib/node_modules/ts-node/dist/bin.js /usr/local/bin/ts-node && \
    # Verify TypeScript installations
    echo "Node.js version: $(node -v)" && \
    echo "TypeScript version: $(npx tsc -v)" && \
    echo "ts-node version: $(ts-node -v)"

# Set NODE_PATH for global modules
ENV NODE_PATH="/usr/lib/node_modules"
ENV PATH="/usr/local/bin:${PATH}"

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN echo "Bun version: $(bun -v)"

# Install Deno
RUN curl -fsSL https://deno.land/install.sh | sh
ENV DENO_INSTALL="/root/.deno"
ENV PATH="${DENO_INSTALL}/bin:${PATH}"
# Create deno config to allow all permissions by default in the container
RUN mkdir -p /root/.deno/config && \
    echo '{ "permissions": { "read": true, "write": true, "net": true, "env": true, "run": true, "ffi": true, "hrtime": true } }' > /root/.deno/config/deno.json
RUN echo "Deno version: $(deno --version)"

# Create working directory
WORKDIR /app

# Copy source files
COPY . .

# Fix JavaScript file extensions (critical for Node.js to work properly)
RUN if [ -f "fib.js.node" ]; then cp fib.js.node fib.node.js; fi && \
    if [ -f "fib.ts.node" ]; then cp fib.ts.node fib.node.ts; fi

# Make scripts executable
RUN chmod +x run_benchmarks.sh prepare_js_benchmarks.sh test_js_env.sh compile_ts.sh
# Ensure JavaScript and TypeScript files have proper permissions
RUN chmod +x fib.js* fib.ts* fib.node.js fib.node.ts

# Prepare JavaScript and TypeScript files
RUN ./prepare_js_benchmarks.sh

# Compile TypeScript files to JavaScript as fallback
RUN ./compile_ts.sh

# Create simple test files to verify JavaScript environment
RUN echo 'console.log("Simple JS test")' > test.js && \
    echo 'console.log("Simple TS test")' > test.ts && \
    chmod +x test.js test.ts

# Test basic Node.js and TypeScript functionality
RUN node -e "console.log('Node.js basic test: SUCCESS')" && \
    node --version && \
    ts-node -e "const x: number = 42; console.log('TypeScript basic test: ' + x);" || echo "Basic ts-node test failed"

# Test JavaScript/TypeScript environments
RUN ./test_js_env.sh

# Verify JS/TS environment
RUN node --version && \
    which node && \
    which ts-node && \
    ts-node --version && \
    deno --version

# Build all implementations
RUN gcc -O3 -o fib_c fib.c && \
    g++ -O3 -o fib_cpp fib.cpp && \
    go build -o fib_go fib.go && \
    gfortran -O3 -o fib_fortran fib.f90 && \
    javac Fib.java && \
    zig build-exe -O ReleaseFast fib.zig && \
    cargo build --release

# Create an entrypoint that runs the benchmarks
ENTRYPOINT ["/app/run_benchmarks.sh"] 