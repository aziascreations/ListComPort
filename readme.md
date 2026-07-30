# PB-ListComPort
A simple CLI tool that lists all COM/Serial ports on a Windows machine.

This tool is intended to replace the tedious task of having to use the `mode` command, and the *Device Manager* to find
a newly plugged-in device that provides a COM port.

A slightly outdated .NET Core port of this utility can be found at
[aziascreations/DotNet-ListComPort](https://github.com/aziascreations/DotNet-ListComPort).

The latest releases can be found here: "*[Release page](https://github.com/aziascreations/ListComPort/releases)*"

> [!NOTE]
> This is utility is in low maintenance mode. \
> I consider it feature-complete, and don't plan on updating it unless a language is added, or a bug is found.


## Features
* Automatic localization *(eng/fra)*
* Usable without CLI
* Supports Windows XP x86/x64 or newer
* Small footprint:
  * HDD: &lt; 100 KiB
  * ~~RAM: ~10 KiB~~ (Investigating issues on this)


## Usage
```
lscom.exe [-h|--help][-a|--show-all] [-d|--show-device]
          [-D <str>|--divider <str>] [-f|--show-friendly] [-h|--help]
          [-n|--show-name-raw] [-P|--no-pretty] [-s|--sort] [-S|--sort-reverse]
          [-t|--tab-padding] [-v|--version] [-V|--version-only]

lscom.exe [/?] [/ShowAll] [/ShowDevice] [/Divider <str>] [/ShowFriendly]
          [/ShowName] [/NoPretty] [/Sort] [/SortReverse] [/TabPadding]
          [/Version]

Options:
  -h, --help, /?                      Displays this help text.
  -a, --show-all, /ShowAll            Displays all the port's names.
                                       Equivalent to using `-dfn`.
  -d, --show-device, /ShowDevice      Displays the port's device name.
  -D, --divider, /Divider <str>       Uses the given string as a separator.
  -f, --show-friendly, /ShowFriendly  Displays the port's friendly name.
  -n, --show-name, /ShowName          Displays the port's raw name. (Default)
  -P, --no-pretty, /NoPretty          Disables the pretty printing format
                                       Equivalent to using `-D `.
  -s, --sort, /Sort                   Sorts the port based on their raw names
                                       in an ascending order
  -S, --sort-reverse, /SortReverse    Sorts the port based on their raw names
                                       in an descending order
  -t, --tab-padding, /TabPadding      Use tabs as a separator (Overrides `-D`)
  -v, --version, /Version             Prints the program's version number
```

### Error codes:
```
Fatal errors: (1-9)
 * 1  - Failed to open terminal
Launch arguments errors: (10-29)
 * 13 - Malfored launch argument
 * 14 - Unknown launch argument
Application errors: (30-39)
 * 30 - No COM port could be found
 * 31 - No friendly name could be found
```

### Output formatting
| Options                  | Output                                         |
|--------------------------|------------------------------------------------|
| *Nothing* or `-n`        | `COM1`                                         |
| `-d`                     | `\Device\Serial1`                              |
| `-f`                     | `Communications Port`                          |
| `-df`                    | `Communications Port [\Device\Serial1]`        |
| `-nd`                    | `COM1 [\Device\Serial1]`                       |
| `-nf`                    | `COM1 - Communications Port`                   |
| `-ndf` or `-a`           | `COM1 - Communications Port [\Device\Serial1]` |
| `-ndfp` or `-ap`         | `COM1 Communications Port \Device\Serial1`     |
| `-ndfD ";"` or `-aD ";"` | `COM1;Communications Port;\Device\Serial1`     |

### Remarks
* If '-d' or '-f' is used, the raw name will not be shown unless '-n' is used.
* If '-D', '-t' or '-p' are used, the special separator between the raw and friendly name and the square brackets are not shown.
* By default, the ports are sorted in the order they are provided by the registry, which is often chronological.
* The 'raw name' refers to a port name. (e.g.: COM1, COM2, ...)
* The 'device name' refers to a port device path. (e.g.: \Device\Serial1, ...)
* The 'friendly name' refers to a port name as seen in the device manager. (e.g.: Communications Port, USB-SERIAL CH340, ...)
* Any result returned with an error code between 1-9 and 30-39 should be considered as invalid.
* Any result returned with another error code is valid but probably not formatted properly.


## Cloning
Use this command to clone the repository and its submodules:
```
git clone --recurse-submodules https://github.com/aziascreations/ListComPort.git
```

If you forgot the submodules, use this command:
```shell
git submodule update --init --recursive
```


## License
All the code in this repo is released in the [Public Domain](LICENSE).
