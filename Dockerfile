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
    && rm -rf /var/lib/apt/lists/*

# Create symlink for dynamic loader (helps with OrbStack compatibility)
RUN mkdir -p /lib64 && \
    ln -s /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 || true

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Julia using the official apt repository
RUN wget -qO- https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.3-linux-x86_64.tar.gz | \
    tar -xz -C /usr/local --strip-components=1

# Install Zig - fixed installation
RUN mkdir -p /opt/zig && \
    wget -O /tmp/zig.tar.xz https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz && \
    tar -xf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 && \
    rm /tmp/zig.tar.xz && \
    ln -s /opt/zig/zig /usr/local/bin/zig

# Create working directory
WORKDIR /app

# Copy source files
COPY . .

# Modified run_benchmarks.sh to handle Julia failure gracefully
RUN sed -i 's/run_benchmark "Julia" "julia fib.jl"/echo "Skipping Julia benchmark due to compatibility issues"/' run_benchmarks.sh || true

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