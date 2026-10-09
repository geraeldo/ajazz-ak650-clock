#!/bin/zsh
set -eu
clock_tool_dir="${0:A:h}"
"$clock_tool_dir/ak650-clock" --timezone Asia/Jakarta
print '\nPress Return to close.'
read -r
