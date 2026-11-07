## ./scripts
 
Each script here does one job on a Linux server and does it in the open, with no hidden dependencies, no silent fallbacks. 

## Troubleshooting: CRLF Line Endings

All scripts must use LF line endings (not CRLF), or they will fail on Linux.
This is enforced by `.vscode/settings.json`.

If a script shows "Literal carriage return" warnings, file not found or fails with
`$'\r': command not found`, convert it:

    sed -i 's/\r$//' script-name.sh
