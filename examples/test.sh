#!/bin/bash -u

FTP_HOST="localhost"
TLS_PORT=2021
SSH_PORT=2022

TEMP_DIR="temp"
TEST_FILE="test.txt"
TEST_CONTENT="test-123"
TEST_PASSWORD="pa55w0rd"

mkdir -p "$TEMP_DIR"
echo "$TEST_CONTENT" > "$TEMP_DIR/$TEST_FILE"

# Function: run FTP test and assert expected result
function test_ftp() {
  local testname=$1
  local protocol=$2
  local username=$3
  local password=$4
  local command=$5
  local expect_success=$6

  echo "/------"
  echo "| $testname/$protocol (user: $username, expected-success: $expect_success)"
  echo "| Command: '$command'"

  # Run lftp quietly, capture output and exit code
  local output
  local code
  local test_settings="set cmd:fail-exit yes; set net:timeout 10; set net:reconnect-interval-base 2; set net:max-retries 1"

  if [[ "$protocol" == "tls" ]]; then
  # TLS FTP
    output=$(lftp -u "$username","$password" -p "$TLS_PORT" "$FTP_HOST" -e "set ssl:verify-certificate no; $test_settings; $command; bye" 2>&1)
  elif [[ "$protocol" == "ssh" ]]; then
    # SSH FTP
    output=$(lftp -u "$username","$password" -p "$SSH_PORT" "sftp://$FTP_HOST" -e "set sftp:auto-confirm yes; $test_settings; $command; bye" 2>&1)
  fi

  code=$?

  # Assertion logic
  if [[ "$expect_success" == "true" && $code -ne 0 ]]; then
    echo "| Result: FAILED, Expected success but got error code '$code'"
    echo "| Output: '$output'"
    exit 1
  elif [[ "$expect_success" == "false" && $code -eq 0 ]]; then
    echo "| Result: FAILED, Expected failure but command succeeded (exit code: $code)"
    exit 1
  else
    echo "| Result: PASSED"
  fi
}


## test cases:

for protocol in "tls" "ssh"; do

  # login
  test_ftp "Test-01" "$protocol" "test-operator" "$TEST_PASSWORD" "ls" true
  test_ftp "Test-02" "$protocol" "invalid-user"  "$TEST_PASSWORD" "ls" false
  test_ftp "Test-03" "$protocol" "test-operator" "wrongpass"      "ls" false

  # user put, operator get&rm
  test_ftp "Test-04" "$protocol" "test-user-a" "$TEST_PASSWORD" "put $TEMP_DIR/$TEST_FILE -o _test/test-a.txt" true
  test_ftp "Test-05" "$protocol" "test-operator" "$TEST_PASSWORD" "ls user-a/_test/" true
  rm -f "$TEMP_DIR/test-a.txt"
  test_ftp "Test-06" "$protocol" "test-operator" "$TEST_PASSWORD" "get user-a/_test/test-a.txt -o $TEMP_DIR/test-a.txt" true
  rm -f "$TEMP_DIR/test-a.txt"
  test_ftp "Test-07" "$protocol" "test-operator" "$TEST_PASSWORD" "rm user-a/_test/test-a.txt" true

  # operator put, user get&rm
  test_ftp "Test-08" "$protocol" "test-operator" "$TEST_PASSWORD" "put $TEMP_DIR/$TEST_FILE -o user-a/_test/test-a.txt" true
  test_ftp "Test-09" "$protocol" "test-user-a" "$TEST_PASSWORD" "ls _test/" true
  rm -f "$TEMP_DIR/test-a.txt"
  test_ftp "Test-10" "$protocol" "test-user-a" "$TEST_PASSWORD" "get _test/test-a.txt -o $TEMP_DIR/test-a.txt" true
  rm -f "$TEMP_DIR/test-a.txt"
  test_ftp "Test-11" "$protocol" "test-user-a" "$TEST_PASSWORD" "rm _test/test-a.txt" true

  # user-b1 put, user-b2 get&rm
  test_ftp "Test-12" "$protocol" "test-user-b1" "$TEST_PASSWORD" "put $TEMP_DIR/$TEST_FILE -o _test/test-b.txt" true
  test_ftp "Test-13" "$protocol" "test-user-b2" "$TEST_PASSWORD" "ls _test/" true
  rm -f "$TEMP_DIR/test-b.txt"
  test_ftp "Test-14" "$protocol" "test-user-b2" "$TEST_PASSWORD" "get _test/test-b.txt -o $TEMP_DIR/test-b.txt" true
  rm -f "$TEMP_DIR/test-b.txt"
  test_ftp "Test-15" "$protocol" "test-user-b2" "$TEST_PASSWORD" "rm _test/test-b.txt" true

  # user-a put, other operator can't get&
  test_ftp "Test-16" "$protocol" "test-other-operator" "$TEST_PASSWORD" "put $TEMP_DIR/$TEST_FILE -o _test/test-o.txt" true
  test_ftp "Test-17" "$protocol" "test-other-operator" "$TEST_PASSWORD" "rm _test/test-o.txt" true
  test_ftp "Test-18" "$protocol" "test-user-a" "$TEST_PASSWORD" "put $TEMP_DIR/$TEST_FILE -o _test/test-a.txt" true
  test_ftp "Test-19" "$protocol" "test-other-operator" "$TEST_PASSWORD" "get user-a/_test/test-a.txt -o $TEMP_DIR/test-a.txt" false
  test_ftp "Test-20" "$protocol" "test-operator" "$TEST_PASSWORD" "rm user-a/_test/test-a.txt" true

done
