import os
import json
import sys


def main():
    print("Correcting CWD...")
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)


    print("Reading config...")
    try:
        with open("_langs_config.json", "r", encoding="utf-8") as f:
            config = json.load(f)
    except Exception as e:
        print("Failed to load/parse config !")
        print(e)
        sys.exit(10)


    print("Reading prefix RC file...")
    rc_prefix = ""
    try:
        if "rc_prefix" in config:
            if config["rc_prefix"] is not None:
                with open(config["rc_prefix"], "r", encoding="utf-8") as f:
                    rc_prefix = f.read().rstrip("\n")
    except Exception as e:
        print("Failed to read the RC prefix file !")
        print(e)
        sys.exit(20)


    print("Reading suffix RC file...")
    rc_suffix = ""
    try:
        if "rc_suffix" in config:
            if config["rc_suffix"] is not None:
                with open(config["rc_suffix"], "r", encoding="utf-8") as f:
                    rc_suffix = f.read().rstrip("\n")
    except Exception as e:
        print("Failed to read the RC suffix file !")
        print(e)
        sys.exit(21)


    print("Reading language files...")
    rc_lines = []

    for lang_path in config["langs"]:
        print(f"Processing '{lang_path}'")

        try:
            with open(lang_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print("Failed to load/parse lang file !")
            print(e)
            sys.exit(30)

        if "_lang" not in data or "_sublang" not in data:
            print("> Cannot continue without `_lang` and `_sublang` being defined !")
            continue

        lang    = data.get("_lang",    "LANG_NEUTRAL")
        sublang = data.get("_sublang", "SUBLANG_NEUTRAL")

        rc_lines.append(f"LANGUAGE {lang}, {sublang}")
        rc_lines.append("STRINGTABLE")
        rc_lines.append("BEGIN")

        for key, value in data.items():
            if key.startswith("_") or not key.isnumeric():
                print(f"-> Skipping   '{key}'")
                continue
            print(f"-> Processing '{key}'")

            if type(value) is list:
                rc_lines.append(f"  {key}, \"{"\\n".join(value)}\"")
            elif type(value) is str:
                rc_lines.append(f"  {key}, \"{value}\"")
            else:
                print(f"--> Unknown data type ! ({type(value)})")

        rc_lines.append("END")
        rc_lines.append("")

    final_text = rc_prefix + "\n" + "\n" + "\n".join(rc_lines) + rc_suffix + "\n"
    try:
        final_text.encode("cp1252")
    except UnicodeEncodeError as e:
        print(repr(final_text[e.start:e.end]), hex(ord(final_text[e.start])))
    #final_text = final_text.replace("\\", "\\\\")
    #final_text = final_text.replace("\\\\\\\\", "\\\\")
    #final_text = final_text.replace("\\\\\\", "\\\\")
    
    with open("StringTables.rc", "w", encoding="cp1252") as f:
        f.write(final_text)

    print("Written: StringTables.rc")
    print("")

if __name__ == "__main__":
    main()
