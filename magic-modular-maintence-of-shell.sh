#!/usr/bin/env zsh

# Run a sequence of magic commands for maintenance with status reporting

echo "--- Running 'magic update' ---"
magic update
if [[ $? -eq 0 ]]; then
  echo "✅ 'magic update' succeeded."
else
  echo "❌ 'magic update' failed. Exiting."
  exit 1
fi

echo # Blank line for separation

echo "--- Running 'magic upgrade' ---"
magic upgrade
if [ $? -eq 0 ]; then
  echo "✅ 'magic upgrade' succeeded."
else
  echo "❌ 'magic upgrade' failed. Exiting."
  exit 1
fi

echo # Blank line for separation

echo "--- Running 'magic self-update' ---"
magic self-update
if [ $? -eq 0 ]; then
  echo "✅ 'magic self-update' succeeded."
else
  echo "❌ 'magic self-update' failed. Exiting."
  exit 1
fi

echo # Blank line for separation

echo "--- Running 'magic clean' ---"
magic clean
if [ $? -eq 0 ]; then
  echo "✅ 'magic clean' succeeded."
else
  echo "❌ 'magic clean' failed. Exiting."
  exit 1
fi

echo # Blank line for separation

echo "--- Running 'magic shell' ---"
# Note: 'magic shell' might replace the current shell process.
# If it succeeds by replacing the process, the success message below might not be shown.
magic shell
if [ $? -eq 0 ]; then
  echo "✅ 'magic shell' completed or launched successfully."
else
  echo "❌ 'magic shell' failed."
  exit 1
fi

echo "--- All commands completed ---"
