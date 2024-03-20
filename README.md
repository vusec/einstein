# Einstein

We present Einstein, a data-only attack exploitation pipeline that uses dynamic taint analysis policies to: (i) scan for chains of vulnerable system calls (e.g., to execute code or corrupt the filesystem), and (ii) generate exploits for those that take unmodified attacker data as input.
Einstein discovers thousands of vulnerable syscalls in common server applications.
Using `nginx` as a case study, we use Einstein to generate 944 mitigation-bypassing exploits.
You can find the full paper [here](https://download.vusec.net/papers/einstein_sec24.pdf).

<!---
## Directory Structure ##

This repository is structured as follows:
-  _**TODO**_
--->

## Description & Requirements ##

### Security, privacy, and ethical concerns ###

Although Einstein indeed produces working exploits, they are non-destructive proof-of-concept exploits, which write the string `"HELLO"` to either a file (`"/tmp/hi"`) or a local socket (address `"192.0.2.0"`).
Hence, evaluating Einstein poses no risks for machine security, data privacy, or other ethical concerns.

### How to access ###

The files for the artifact evaluation are available at the [`ae` tag of the repository](https://github.com/vusec/einstein/releases/tag/ae).

### Hardware dependencies ###

Einstein requires an x86-64 machine (Intel recommended), enough RAM to run the instrumented target programs (minimum 48 GB), and enough storage for hundreds of program snapshots (minimum 2 TB for this evaluation).
We recommend using a machine with a high core count to speed up Einstein's report post-processing.

### Software dependencies ###

To build Einstein and the target programs, we expect certain packages to be installed.
In the [Set-up section](#Set-up), we detail the steps to install such dependencies on Ubuntu 22.04, but similar steps are needed for other distributions.

### Benchmarks ###

We use each target application's test suite to drive the analysis.

## Set-up ##

To download and install dependencies, including [go-task](https://taskfile.dev/#/installation) as a task-runner, from this repository, run: `sudo snap install task --classic && task init`.

### Installation ###

To build [libdft](https://github.com/vusec/libdft64-ng), the command server, the Einstein tool, and all target applications, run: `task libdft-build cmdsvr-build einstein-build apps-build`.

### Basic Test ###

Next, test that the different components work as follows. Note for any commands that run the `db-analyze-reports` task: If it fails, try running the `db-analyze-reports-singleproc` task instead. It will be slower, but will avoid any load-related crashes.

- To test libdft's "taint all memory" functionality, run `task libdft-test -- memtaint` and compare its output to the [expected output](https://github.com/vusec/libdft64-ng/blob/master/tests/memtaint.expected.out). Note that the addresses in the actual output may differ from the addresses in the expected output.
- To test libdft's per-instruction taint policies, run `task libdft-test -- ins` and compare its output to the [expected output](https://github.com/vusec/libdft64-ng/blob/master/tests/ins.expected.out). Note that the addresses in the actual output may differ from the addresses in the expected output.
- To test Einstein on a simple program, run `task einstein-test`. Then, compare the output of `task db-print-candidates` with the [expected output](apps/tests/src/tainted-syscall.expected.out).
- To test Einstein on each target application running a simple workload (e.g., sending a simple GET request to a web server), run `task reports-clean apps-test db-add-reports db-analyze-reports`. Then, compare the output of `task db-print-candidates` with the [expected output](results/reports/expected/apps-test-candidates.expected.out).
- To test Einstein's exploit confirmation for `nginx`, run `task reports-clean einstein-nowrite-config nginx-eval-custom db-add-reports db-analyze-reports db-analyze-candidates`. Then, compare the output of `task db-print-exploits` with the [expected output](results/reports/expected/nginx-custom-exploits.expected.out).

## Evaluation Workflow ##

### Major Claims ###

We make the following claims:
- **(C1)**: *Einstein identifies thousands of vulnerable syscalls in common server applications. This is proven by Experiment (E1).*
- **(C2)**: *Einstein generates hundreds of working exploits against `nginx`. This is proven by Experiment (E2).*

### Experiments ###

We prove the above claims using the following experiments:

#### (E1): Confirming vulnerable syscall identification for all target applications. [30 human-minutes + 24 compute-hours] ####

- How to: We will run each application with Einstein, then analyze the reports to identify vulnerable syscalls.
- Preparation: Run `task reports-clean` to remove past reports.
- Execution: Run `task apps-eval db-add-reports db-analyze-reports`.
- Results: Compare the output of `task db-print-candidates` to the [expected output](results/reports/expected/apps-candidates.expected.out). The output contains thousands of vulnerable gadgets, broken down by: (i) syscall and argument type (i.e., Table 3), and (ii) target application (i.e., Table 4)—thereby proving Claim (C1).

#### (E2): Confirming exploit generation for `nginx`. [30 human-minutes + 12 compute-hours] ####

- How to: We will run `nginx` with Einstein, then analyze the reports to identify vulnerable syscalls, then confirm candidate exploits as working exploits.
- Preparation: Run `task reports-clean` to remove past reports.
- Execution: Run `task nginx-eval db-add-reports db-analyze-reports db-analyze-candidates`.
- Results: Compare the output of `task db-print-exploits` to the [expected output](results/reports/expected/nginx-exploits.expected.out). The output contains hundreds of confirmed exploits for `nginx` (i.e., Table 5)—thereby proving Claim (C2).

## Notes on Reusability ##

This prototype may be expanded in a few directions:

- To modify Einstein's taint policies (e.g, to target more syscalls, or to target [syscall-guard variables](https://www.usenix.org/conference/usenixsecurity23/presentation/ye)), modify the Einstein tool in `src/einstein`.
- To run the target applications (e.g., `nginx`) with other workloads, first start the application with Einstein (`cd apps/nginx-1.23.0 && RUN_EINSTEIN=1 ./serverctl restart`), then run the custom workload (e.g., `echo 'Hello!' | netcat 127.0.0.1 1080`).
- To run Einstein on other applications:
  - (i) Add the application to the `apps/` directory;
  - (ii) Copy the files `serverctl` and `clientctl` from another application's directory into its directory, and modify them to start the application's server and a client for it; and
  - (iii) Ensure that the application's build script generates position-independent code (i.e., the default on most compilers).
- To write another Pin tool that uses libdft64-ng:
  - (i) Copy the Einstein tool, e.g.: `cp -r src/einstein src/my-tool`;
  - (ii) Modify `MY_TOOL` and `MY_OBJS` in the `Makefile`;
  - (iii) Modify the source code to suite your analysis;
  - (iv) Build it: `cd src/my-tool && -DLIBDFT_TAG_PTR -DLIBDFT_PTR_32 -DLIBDFT_TAG_SSET_MAX=16' make obj-intel64/my-tool.so`; and
  - (v) Run it on some target application: `setarch x86_64 -R ./src/misc/pin-3.28-98749-g6643ecee5-gcc-linux/pin -t src/my-tool/obj-intel64/my-tool.so -- echo 'Hello!'`.
