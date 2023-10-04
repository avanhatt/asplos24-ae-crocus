# Artifact Evaluation: Lightweight, Modular Verification for WebAssembly-to-Native Instruction Selection (Crocus)

These instructions are hosted in an archival repository at XXXX. 

# Abstract

This directory contains the evaluation scripts for our ASPLOS 2024 paper, Lightweight, Modular Verification for WebAssembly-to-Native Instruction Selection.

Crocus is a new tool for verifying the correctness of instruction lowering rules written in ISLE, a domain-specific rewriting language. Our initial implementation of Crocus as described in the paper focuses on verifying integer operations in WebAssembly 1.0 within Cranelift, a retargetable native code generator. Cranelift and Crocus are primarily implemented in Rust; our evaluation consists of Rust unit tests and Python scripts.

In this artifact, we provide instructions for reproducing each of the major empirical results in the paper:
1. A Python script that invokes and counts Rust tests that use Crocus to verify rules in the ARM `aarch64` backend (Table 1).
1. Rust commands/tests for six of the listed case studies (Section 4.3.1, Section 4.3.2, Section 4.3.3, Section 4.4.1, Section 4.4.2, Section 4.4.4).
1. A Github issue for the 7th case study, an under-specified compiler invariant (Section 4.4.3).
1. Bash and Python scripts to characterize the percent of rules we have covered (Section 4.2) and the verification run-times (Figure 4).

We estimate the required components of this artifact to take around 1.5-2 hours of reviewer time (with additional 
optional components listed as such). 

> [!Note]  
> We list important components as notes.

----
## Machine requirements

The majority of our artifact should perform as expected on most CPUs, including laptops.

> [!WARNING]  
> However, to fully reproduce one result (our rule coverage experiment), we require access
 to a machine with ARM `aarch64` (e.g., an M1 or M2 Mac). However, we have including pre-saved build traces for 
`aarch64` compilations as well as the scripts to analyze them, in case a reviewer does not have access 
to an `aarch64` machine (this experiment is not one of our core results).

----

## Table of Contents
* [Part 0: Setup](#part-0-setup)
   * [Option 1: Docker (recommended) [est. 5-10 minutes]](#option-1-docker-recommended-est-5-10-minutes)
   * [Option 2: Install from source (skip if using Docker) [optional est. 10-30 minutes]](#option-2-install-from-source-skip-if-using-docker-optional-est-10-30-minutes)
* [Part 1: Wasm 1.0 to ARM aarch64 rule suite [est. 10-30 minutes]](#part-1-wasm-10-to-arm-aarch64-rule-suite-est-10-30-minutes)
   * [Table 1: Verification results for the Wasm 1.0 to ARM aarch64 rule suite [est. 10-30 minutes]](#table-1-verification-results-for-the-wasm-10-to-arm-aarch64-rule-suite-est-10-30-minutes)
   * [Figure 4: Cumulative Distribution Function (CDF) of verification runtimes [est. 10-30 minutes]](#figure-4-cumulative-distribution-function-cdf-of-verification-runtimes-est-10-30-minutes)
* [Part 2: Case studies [est. 30-45 minutes]](#part-2-case-studies-est-30-45-minutes)
   * [Case study 4.3.1: x86-64 addressing mode CVE (9.9/10 severity, previously known)  [est. 5 minutes]](#case-study-431-x86-64-addressing-mode-cve-9910-severity-previously-known--est-5-minutes)
   * [Case study 4.3.2: aarch64 unsigned divide CVE (moderate severity, previously known) [est. 5 minutes]](#case-study-432-aarch64-unsigned-divide-cve-moderate-severity-previously-known-est-5-minutes)
   * [Case study 4.3.3: aarch64 count-leading-sign bug (previously known) [est. 5 minutes]](#case-study-433-aarch64-count-leading-sign-bug-previously-known-est-5-minutes)
   * [Case study 4.4.1: Another addressing mode bug (x86-64) [est. 5 minutes]](#case-study-441-another-addressing-mode-bug-x86-64-est-5-minutes)
   * [Case study 4.4.2: Flawed negated constant rules (aarch64) [est. 5 minutes]](#case-study-442-flawed-negated-constant-rules-aarch64-est-5-minutes)
   * [Case study 4.4.3: Imprecise semantics for constants in Cranelift IR (all backends) [est. 5 minutes]](#case-study-443-imprecise-semantics-for-constants-in-cranelift-ir-all-backends-est-5-minutes)
   * [Case study 4.4.4: A mid-end root cause analysis (all backends) [est. 5 minutes]](#case-study-444-a-mid-end-root-cause-analysis-all-backends-est-5-minutes)
* [Part 3: Rule coverage [est. 15 minutes]](#part-3-rule-coverage-est-15-minutes)
* [End](#end)

----

# Part 0: Setup 


## Option 1: Docker (recommended) [est. 5-10 minutes]

### Install Docker if needed [est. 5 minutes]

We provide our artifact as a [Docker][docker] instance (recommended). Users should install Docker based on their system's instructions. Alternatively, our artifact can be evaluated by installing from source.

[docker]: https://docs.docker.com/engine/installation/

### Optional: increase memory available to Docker  [est. 5 minutes] 

Our artifact performs better with >2GB of memory available (a limit imposed by some Docker configurations). To check how much memory is available to the running Docker container, open a second terminal on the host machine (not within the Docker shell) and run:
```
docker stats
```

Check the column titled `MEM USAGE / LIMIT`. On macOS/Windows, the second value of limit may initially be `1.939GiB`, because although native Docker on Linux [does not default to having memory limits][docker-mem], [Docker Desktop for Mac][docker-mac] and [Docker Desktop for Windows][docker-windows] have a 2GB limit imposed. 

You can increase the Docker Desktop memory limit to (e.g., to 4GB or 8GB) by following the links above or these steps:
1. Open Docker Desktop.
2. Open Setting (gear icon).
3. Click Resources on the side bar.
4. Increase the Memory bar.

Similarly, if you are running Docker within a virtual container or cloud instance, follow the instructions from that provider.

[docker-mem]: https://docs.docker.com/config/containers/resource_constraints/
[docker-mac]: https://docs.docker.com/desktop/mac/
[docker-windows]: https://docs.docker.com/desktop/windows/

### Fetch and run the Docker instance [est. 5 minutes, depending on internet strength]

The remainder of this artifact assumes all commands are run within the Docker instance.

To interactively run the Docker instance, run the following:

```bash
docker run -i -t --rm ghcr.io/avanhatt/crocus:0.1
```

Inside the docker, you will be placed in the directory `/root/wasmtime/cranelift/isle/veri/veri_engine` 
(our fork of `wasmtime`/Cranelift, on the branch `asplos24-ae`).

From there, pull to get any of the latest updates to the `asplos24-ae` branch:

```bash
git pull
```

### Optional: open running instance in VSCode [est. 5 minutes]

We recommend connecting to the running Docker instance in [VSCode][] or another IDE that enables connecting to instances, so you can view files (including PDFs/images) interactively. Instructions for VSCode can be found here: [VSCode attach container][].

[vscode]: https://code.visualstudio.com
[VSCode attach container]: https://code.visualstudio.com/docs/devcontainers/attach-container

## Option 2: Install from source (skip if using Docker) [optional est. 10-30 minutes]

<details>
  <summary>Instructions to alternatively install from source >></summary>

### Python
- Install [Python][] >= `3.0`.
- You will also need the following Python packages:
    - `pip3 -mpip install matplotlib tabulate`

### Rust
- Install [Rust][] >= `rustc 1.72.1`.

### Z3

- Install [z3] >= `4.12.2` (older versions of z3 may timeout on more tests than expected).

[python]: https://www.python.org/downloads/
[rust]: https://www.rust-lang.org/tools/install
[z3]: https://github.com/Z3Prover/z3

</details>

# Part 1: Wasm 1.0 to ARM `aarch64` rule suite [est. 10-30 minutes]

## Table 1: Verification results for the Wasm 1.0 to ARM `aarch64` rule suite [est. 10-30 minutes]

Each of the rules that we verify that lower from from Wasm 1.0 to ARM `aarch64` 
have annotations in-tree, in specific ISLE files. To verify each of these rules, we have one or more unit
tests that invoke Crocus on the specified rule (as named in the ISLE source code with `(rule NAME ...)`).

We have provided a single script that runs each of these named tests (via Rust's unit testing
infrastructure, `cargo test`). By default, tests that are known to timeout are skipped (by 
being marked as `#[ignore]` within the Rust test file). To 
automate our counting of the number of such skipped tests, we then use a `SKIP_SOLVER` environment variable 
to run the ignored tests in a second pass, stopping such before the non-terminating solver query.

Our script writes the output for both the tests that are expected to terminate and 
the tests that are known to timeout to a timestamped log file: `script-results/wasm-1.0-to-aarch64-log--<timestamp>.txt`.

The second part of the script analyzes the log file to count the total number of rules and type innovations. It emits the counts as a table, first with formatting 
to be included in our paper (LaTeX), then with formatting for this artifact evaluation (an ASCII table). 
The table checks that the expected number of failures are 2/4, since
manual inspection of the ISLE rules is necessary to determine that the do not represent true failures.

> [!NOTE]  
> To reproduce Table 1, run the following script:

```bash
python3 scripts/wasm1.0-to-aarch64.py 
```

You should see the following final output to standard out:
```
               Total  Success                         Timeout                        Inapplicable    Failure
-----------  -------  ------------------------------  -----------------------------  --------------  ---------
Rules             98  86 (all types) / 93 (any type)  10 (any type) / 5 (all types)  N/A             2 (0)
Type Insts.      377  245                             28                             104             4 (0)
```

### Optional: additional manual inspection [optional est. 30 min]

<details>
  <summary>Optional details on manually viewing the log file and rules >> </summary>

You can also inspect the raw log file, which is written to:
1. `script-results/wasm-1.0-to-aarch64-log--<timestamp>.txt`

Further, you can find each rule and it's corresponding annotations by searching for those strings in the repository.

To view each rule, you can find the name of the rule within the log. For example, if you pick
`VERIFYING rule with name: iadd_ishl_left` from the log, you can find that rule by searching for `iadd_ishl_left` in the repository.
You would find:
```lisp
(rule iadd_ishl_left 6 (lower (has_type (fits_in_64 ty)
                       (iadd (ishl x (iconst k)) y)))
      (if-let amt (lshl_from_imm64 ty k))
      (add_shift ty y x amt))
```

You can then search for an annotation, e.g., for `lshl_from_imm64`, by searching for `(spec (lshl_from_imm64`, finding:
```lisp
(spec (lshl_from_imm64 ty a)
    (provide (= result (concat #x0e (extract 7 0 a))))
    (require (= (extract 63 8 a) #b00000000000000000000000000000000000000000000000000000000)))
(decl pure partial lshl_from_imm64 (Type Imm64) ShiftOpAndAmt)
```

</details>

## Figure 4: Cumulative Distribution Function (CDF) of verification runtimes [est. 10-30 minutes]

We create a Cumulative Distribution Function (CDF) via a Python script that 
times a list of expected successful Rust cargo tests, adds to the total number
of tests a list of tests that are known to timeout, and plots the results with `matplotlib`.

To reproduce the CDF including timing the expected successful tests from inside the `veri_engine`
directory (`/root/wasmtime/cranelift/isle/veri/veri_engine`).


> [!NOTE]  
> To reproduce Figure 4, run the following script:

```bash
python3 scripts/cdf.py
```

This will create two new, time-stamped results file in the subdirectiory `script-results`. Note that for the
purposes of generating a plot with `matplotlib`, we consider tests that timeout to have an
arbitrarily large runtime (outside the bounds of the plot, 10000000). Because verification times
are not a core contribution of this work, we do not run multiple measurements of the same test.

1. `script-results/cdf-results-<timestamp>.txt` a text file listing the runtimes in ascending order.
1.  `script-results/cdf-<timestamp>.pdf` the PDF image, as shown in the paper. (Note, you can copy this file to your host machine if needed with `docker cp <container>:/root/wasmtime/cranelift/isle/veri/veri_engine/script-results/cdf-<timestamp>.pdf .`)

# Part 2: Case studies [est. 30-45 minutes]

## Case study 4.3.1: `x86-64` addressing mode CVE (9.9/10 severity, previously known)  [est. 5 minutes]

Our annotation needed to reproduce this bug are in a self-contained file, `examples/x86/amode_add_uextend_shl.isle`.
The problematic rule itself is at the bottom of this file:

```lisp
(rule 2 (amode_add (Amode.ImmReg off (valid_reg base) flags) 
                   (uextend (ishl index (iconst (uimm8 shift)))))
      (if (u32_lteq (u8_as_u32 shift) 3))
      (Amode.ImmRegRegShift off base (extend_to_gpr index $I64 (ExtendKind.Zero)) shift flags))
```

The rest of the file contains ISLE definitions and Crocus specification `(spec ...)` blocks.

> [!NOTE]  
> To reproduce case study 4.3.1, run:

```bash
cargo run -- --noprelude -t amode_add -i examples/x86/amode_add_uextend_shl.isle
```

You'll see something a counterexample output like this at the end of the trace (the exact output may differ, you 
need only check that the final two lines contain non-equal hex and binary values):

```lisp
Verification failed
Counterexample summary
(amode_add (Amode.ImmReg [off|#x04208041|0b00000100001000001000000001000001] (valid_reg [base|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000]) [flags|#x0|0b0]) (def_inst (uextend (def_inst (ishl [index|#x5e350102|0b01011110001101010000000100000010] (def_inst (iconst (uimm8 [shift|#x02|0b00000010]))))))))
=>
(Amode.ImmRegRegShift [off|#x04208041|0b00000100001000001000000001000001] (gpr_new [base|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000]) (extend_to_gpr [index|#x5e350102|0b01011110001101010000000100000010] (I64) (ExtendKind.Zero)) [shift|#x02|0b00000010] [flags|#x0|0b0])

#x000000007cf48449|0b000000000000000000000000000000000001111100111101001000010001001001 =>
#x000000017cf48449|0b000000000000000000000000000000000101111100111101001000010001001001
```

As described in the paper, you can see that the second value after the `=>` (representing the right-hand-side) has a bit set in the upper 32 bits, 
indicating a potential sandbox escape based on the intended security invariants of Cranelift's lowering 
to native addresses.

## Case study 4.3.2: `aarch64` unsigned divide CVE (moderate severity, previously known) [est. 5 minutes]

In this case study, the core issue is that the immediate `imm` construct previously did not specify
whether the value should be sign- or zero-extended. The previous version of `imm` looked 
like this (with a Crocus specification):

```lisp
(spec (imm ty x) 
  (provide (= result (sign_ext 64 (conv_to ty x)))))
(decl imm (Type u64) Reg)
```

The core issue is demonstrated by this test, which executes Crocus on the file 
`examples/broken/udiv/udiv_cve_underlying.isle`. 

> [!NOTE]  
> To reproduce case study 4.3.2, run:

```bash
cargo test test_broken_imm_udiv_cve_underlying_32 -- --nocapture
```

If you edit line 12 of `examples/broken/udiv/udiv_cve_underlying.isle` to use `zero_ext` 
instead of `sign_ext`, you'll see that the test still fails, demonstrating that the ISLE
signature for `imm` was previously insufficient to lower immediates of this form.

```
Verification failed
Counterexample summary
(imm (integral_ty [_ty|32]) [n|#x0000000100000000|0b000000000000000000000000000000000100000000000000000000000000000000])
=>
(load_constant64_full [n|#x0000000100000000|0b000000000000000000000000000000000100000000000000000000000000000000])

#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000 =>
#x0000000100000000|0b000000000000000000000000000000000100000000000000000000000000000000
```

The fixed rule uses this version of `imm`, which does take in an argument, `ImmExtend`, for whether to 
zero or sign extend:

```lisp
(decl imm (Type ImmExtend u64) Reg)
```

## Case study 4.3.3: `aarch64` count-leading-sign bug (previously known) [est. 5 minutes]

In this test, the rule for counting the leading sign bit of a value incorrectly zero- instead of sign-
extended. 

The problematic older version of the rule can be found in the file `examples/broken/cls/broken_cls8.isle`:

```lisp
(rule (lower (has_type $I8 (cls x)))
      (sub_imm $I32 (a64_cls $I32 (put_in_reg_zext32 x)) (u8_into_imm12 24)))
```


> [!NOTE]  
> To reproduce case study 4.3.3, run:

```
cargo test test_broken_cls_8 -- --nocapture
```

As expected, Crocus gives us a counterexample where values are incorrectly zero-extended. 
In this counterexample, the RHS 
gives -1 as the number of leading sign digits instead of the correct 3 for the value `0b11110000`. 
The exact counterexample you see may differ. 

```
Verification failed
Counterexample summary
(lower (has_type (I8) (cls [x|#xf0|0b11110000])))
=>
(output_reg (sub_imm (I32) (a64_cls (I32) (put_in_reg_zext32 [x|#xf0|0b11110000])) (u8_into_imm12 (24))))

#x03|0b00000011 =>
#xff|0b11111111
```

## Case study 4.4.1: Another addressing mode bug (`x86-64`) [est. 5 minutes]

Like the previous addressing mode bug, this is a self-contained file for x86-64 addressing modes.

> [!NOTE]  
> To reproduce case study 4.4.1, run:

```bash
cargo run -- --noprelude -t amode_add -i examples/x86/amode_add_shl.isle
```

This time, the last output should show `Verification Success`. This is because for a 64 bit input 
value, this rule is not problematic, since this is no sign- or zero extension involved.


However, if you scroll up in the trace, you will see that the 32 bit input fails with a counterexample.
You will see an counterexample output that looks something like this:
```
Verification failed
Counterexample summary
(amode_add (Amode.ImmReg [off|#x00000010|0b00000000000000000000000000010000] (valid_reg [base|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000]) [flags|#x0|0b0]) (def_inst (ishl [index|#xfffffff0|0b11111111111111111111111111110000] (def_inst (iconst (uimm8 [shift|#x00|0b00000000]))))))
=>
(Amode.ImmRegRegShift [off|#x00000010|0b00000000000000000000000000010000] (gpr_new [base|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000]) (put_in_gpr [index|#xfffffff0|0b11111111111111111111111111110000]) [shift|#x00|0b00000000] [flags|#x0|0b0])

#x0000000100000000|0b000000000000000000000000000000000100000000000000000000000000000000 =>
#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000
```

Optional: you can see the Github issue where this issue was fixed here: 
[Cranelift: x64, aarch64, s390x, riscv64: ensure addresses are I64s][].

[Cranelift: x64, aarch64, s390x, riscv64: ensure addresses are I64s]: https://github.com/bytecodealliance/wasmtime/pull/5972

## Case study 4.4.2: Flawed negated constant rules (`aarch64`) [est. 5 minutes]

In this case study, the issue is that a prior version of rules for adding and subtracting negated 
constant values, and ISLE terms were erroneously designed such that some rules would never apply.

One such problematic previous rule is in the file `examples/broken/isub/broken_imm12neg_not_distinct.isle`.
The rule is this:
```
;; BROKEN: for ty < 64, this only matches on zero
(rule 2 (lower (has_type (fits_in_64 ty) (isub x (imm12_from_negated_value y))))
    (add_imm ty x y))
```

This case study shows how Crocus identified this type of overly-restrictive flaw.

> [!NOTE]  
> To reproduce Case study 4.4.2, run:
```
cargo test test_isub_imm12_neg_not_distinct_16_32 -- --nocapture
```

You will see the trace contains the following, which indicates that the rule fails the 
model distinctness check:
```
Assertion list is only feasible for one input with distinct BV values!
```

Optional: you can view our original bug report ([Cranelift: ISLE: aarch64: imm12_from_negated_value rules don't apply for i32, i16][]) and accepted fix for this issue on Github ([Cranelift: ISLE: aarch64: fix imm12_from_negated_value for i32, i16][]).

[Cranelift: ISLE: aarch64: imm12_from_negated_value rules don't apply for i32, i16]: https://github.com/bytecodealliance/wasmtime/issues/5903
[Cranelift: ISLE: aarch64: fix imm12_from_negated_value for i32, i16]: https://github.com/bytecodealliance/wasmtime/pull/6078
## Case study 4.4.3: Imprecise semantics for constants in Cranelift IR (all backends) [est. 5 minutes]

Our work on Crocus led us to identify that semantics for constants in Cranelift IR were previously imprecise:
it was not specified whether the upper-bits of a narrow constant should be zero- or sign- extended.

> [!NOTE]  
> To see case study 4.4.3, view: 

The Github issue that documented this issue can be found here: [Cranelift/ISLE: precise semantics for narrow iconsts][].

A fix for one component of the problem, that the Cranelift validator did not check for either option, has 
since landed with this change from a different Cranelift contributor: [Validate const value ranges in CLIF Validator][].

[Cranelift/ISLE: precise semantics for narrow iconsts]: https://github.com/bytecodealliance/wasmtime/issues/5700
[Validate const value ranges in CLIF Validator]: https://github.com/bytecodealliance/wasmtime/issues/3059

## Case study 4.4.4: A mid-end root cause analysis (all backends) [est. 5 minutes]

Our annotations to reproduce this bug are in a standalone file, `examples/mid-end/broken_bor_band_consts.isle`.

> [!NOTE]  
> To reproduce case study 4.4.4, run:

```
cargo run -- --noprelude -t simplify -i examples/mid-end/broken_bor_band_consts.isle
```

You will see a counterexample output something like this:
```
Verification failed
Counterexample summary
(simplify (bor [ty|64] (band [ty|64] [x|#x0000000000000001|0b000000000000000000000000000000000000000000000000000000000000000001] (iconst [ty|64] (u64_from_imm64 [y|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000]))) ([z|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000] @ (iconst [ty|64] (u64_from_imm64 [zk|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000])))))
=>
(bor [ty|64] [x|#x0000000000000001|0b000000000000000000000000000000000000000000000000000000000000000001] [z|#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000])

#x0000000000000000|0b000000000000000000000000000000000000000000000000000000000000000000 =>
#x0000000000000001|0b000000000000000000000000000000000000000000000000000000000000000001
```

As you can see, if you truncate this counterexample to the lowest two bits, this matches the incorrect result
described in this section.

# Part 3: Rule coverage [est. 15 minutes]

In this section, we instrument Wasmtime/Cranelift to determine the percent of invoked rules Crocus covers.
Because we implemented basic tracing logic on an a earlier version of Wasmtime/Cranelift that has since 
changed, this subsection is based on a different branch.

> [!WARNING]  
> This section can only be exactly reproduced on a machine with ARM `aarch64` (e.g., an M1 or M2 Mac). We provide pre-saved rule traces if you do not have access to such a machine.

First checkout the specific branch that tracks these rule statistics and navigate to the root of the directory:

```bash
git checkout rule-stats
git pull
cd /root/wasmtime/
```

> [!WARNING]  
> On a NON-`aarch64` machine, run the command on our saved result:

```bash
python3 rule-stats.py < cranelift/isle/veri/veri_engine/script-results/rule-trace-wasmtime-saved.csv
```

Otherwise, to fully reproduce these results on an `aarch64` machine,  build the instrumented version of Cranelift with:

```bash
cargo build
```

On an `aarch64` machine, next, run the following command to generate a timestamped trace file of the instrumented version of Cranelift run on the Wasm `spec_testsuite`, minus tests that use WebAssembly features beyond Wasm 1.0:
```
./stats-collect.sh
```

On an `aarch64` machine, next, analyze the most recently-generated trace file:
```
fn=`ls -tr rule-trace-*.csv | tail -n1`
python3 rule-stats.py < $fn
```

You should see the following bottom-most results:
```
Named uses: 22634/97790 = 23.1%
Named covered: 50/253 = 19.8%
```

Next, we'll run the same tracing logic on different tests, from the `rustc_codegen_cranelift` alternative backend for Rust.

> [!WARNING]  
> On a NON-`aarch64` machine, run the command on our saved result:

```bash
python3 rule-stats.py < cranelift/isle/veri/veri_engine/script-results/rule-trace-rustc_codegen_cranelift-saved.csv
```

On an `aarch64` machine, navigate to that directory (and pull any changes to our specific branch):
```bash
cd ../rustc_codegen_cranelift
git pull
```

On an `aarch64` machine, write the tracing output to a new log:
```bash
TARGET_TRIPLE=aarch64-unknown-linux-gnu ./test.sh > rule-trace-rustc_codegen_cranelift.csv
```

On an `aarch64` machine, finally, analyze the output with:
```bash
python3 ../wasmtime/rule-stats.py < rule-trace-rustc_codegen_cranelift.csv
```

Where you should see these results:
```
Named uses: 610/2305 = 26.5%
Named covered: 24/152 = 15.8%
```
# End

Exit the Docker terminal with `ctrl+d`. Thank you for your time!
