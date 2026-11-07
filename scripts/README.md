## ./scripts
 
Each script here does one job on a Linux server and does it in the open with no hidden dependencies and no silent fallbacks. 

## Troubleshooting: CRLF Line Endings

All scripts must use LF line endings (not CRLF), if you receive an error when trying to execute a script, execute:
```bash
    sed -i 's/\r$//' script-name.sh
```

or on all scripts:

```bash
    sed -i 's/\r$//' scripts/*
```
