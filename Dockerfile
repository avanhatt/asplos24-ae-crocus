# Use a recent Ubuntu as the parent image.
FROM ubuntu:20.04

USER root

# Install some system level dependencies
RUN apt-get update 
RUN apt-get install -y sudo git time python3 python3-pip curl wget unzip

# Install a specific version of Z3 from source
WORKDIR /root
RUN wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.12.2.zip
RUN unzip z3-4.12.2.zip
WORKDIR z3-z3-4.12.2/
RUN python3 scripts/mk_make.py
WORKDIR build
RUN make
RUN make install

# Install Rust toolchain
WORKDIR /root
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Python dependencies
RUN pip3 install matplotlib tabulate

# Clone our Wasmtime fork, which includes the Crocus implementation
WORKDIR /root
RUN git clone -b asplos24-ae https://github.com/avanhatt/wasmtime
WORKDIR /root/wasmtime/cranelift/isle/veri/veri_engine
RUN mkdir script-results
RUN git config --global user.email "placeholder"
RUN git config --global user.name "placeholder"
RUN git pull -f
RUN git submodule update --init

# Clone the `rustc_codegen_cranelift` for part of our coverage results
WORKDIR /root
RUN git clone https://github.com/sampsyo/rustc_codegen_cranelift.git
WORKDIR /root/rustc_codegen_cranelift
RUN git checkout back-in-time
RUN ./y.rs prepare

# Navigate back to the Crocus directory
WORKDIR /root/wasmtime/cranelift/isle/veri/veri_engine

