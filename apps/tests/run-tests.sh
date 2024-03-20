#!/bin/bash

run_cmdsvr_test() {
  TEST=build/cmdsvr-taintall
  echo "================================"
  echo "** Running test $(basename ${TEST})"
  RUN_EINSTEIN=1 PROC_NAME=$(basename ${TEST}) ./serverctl restart &
  sleep 4
  echo "** Sending 'taintall' command..."
  RUN_EINSTEIN=1 PROC_NAME=$(basename ${TEST}) ./serverctl udscmd pids dbt taintall
  echo "** Telling test to continue..."
  RUN_EINSTEIN=1 PROC_NAME=$(basename ${TEST}) ./serverctl sigusr1
  sleep 2
  RUN_EINSTEIN=1 PROC_NAME=$(basename ${TEST}) ./serverctl stop
  sleep 2
}

run_indirect_test() {
  TEST=build/indirect-call
  echo "================================"
  echo "** Running test $(basename ${TEST})"
  setarch x86_64 -R ${PIN_ROOT}/pin -t ${INSTALL_DIR}/einstein.pin -- ${TEST}
}

run_load_ptr_prop_test() {
  TEST=build/load-ptr-prop
  echo "================================"
  echo "** Running test $(basename ${TEST})"
  setarch x86_64 -R ${PIN_ROOT}/pin -t ${INSTALL_DIR}/einstein.pin -- ${TEST}
}

run_syscall_test() {
  TEST=build/tainted-syscall
  echo "================================"
  echo "** Running test $(basename ${TEST})..."
  RUN_EINSTEIN=1 USE_LOG_DIR=1 V=1 LOG_SUB_DIR=$(basename ${TEST}) PROC_NAME=$(basename ${TEST}) ./serverctl restart
  RUN_EINSTEIN=1 USE_LOG_DIR=1 V=1 LOG_SUB_DIR=$(basename ${TEST}) PROC_NAME=$(basename ${TEST}) ./serverctl stop
}

run_syscall_test_minimal() {
  TEST=build/tainted-syscall
  echo "================================"
  echo "** Running test $(basename ${TEST})..."
  RUN_EINSTEIN=1 V=1 PROC_NAME=$(basename ${TEST}) ./serverctl restart
  RUN_EINSTEIN=1 V=1 PROC_NAME=$(basename ${TEST}) ./serverctl stop
}

run_check_mem_taint_test() {
  TEST=build/check-mem-taint
  echo "================================"
  echo "** Running test $(basename ${TEST})"
  setarch x86_64 -R ${PIN_ROOT}/pin -t ${INSTALL_DIR}/einstein.pin -- ${TEST}
}

if [[ -n "$1" ]] && [[ $1 == "minimal" ]]; then
   run_syscall_test_minimal
   exit 0
fi

#run_cmdsvr_test
#run_indirect_test
#run_load_ptr_prop_test
run_syscall_test
#run_check_mem_taint_test

