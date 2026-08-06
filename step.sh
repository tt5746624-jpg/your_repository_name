#!/system/bin/sh
# =====================================================================
# MLBB Document.unity3d Full Native Editor v3.9.0
# Integrated with: Advanced Config Builder (Drone, Maphack, Damage Font)
# =====================================================================

NAME="MLBB Document Editor"
VERSION="3.9.0 | Xoni & Automated Builder"

# ========== COLORS ==========
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
M='\033[0;35m'
C='\033[0;36m'
N='\033[0m'
W='\033[1;37m'

# ========== DEFAULT GLOBAL PATHS ==========
BASE="/storage/emulated/0"
DEFAULT_MLBB_DATA="$BASE/Android/data/com.mobile.legends/files"
DEFAULT_OUT_DIR="$BASE/MLBB_Extracted"

DOCUMENT_PATH=""
OUTPUT_DIR=""

# ========== UTILS ==========
clean_path() {
    echo "$1" | sed "s/^['\"]//;s/['\"]$//;s/[[:space:]]*$//"
}

setup_paths() {
    echo -e "\n${C}┌─── [ CONFIGURATION / PATH SETTINGS ] ────────────────┐${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Document.unity3d file path:${N}"
    echo -e "${C}│${N} ${B}    Default -> $DEFAULT_MLBB_DATA/Document.unity3d${N}"
    echo -n -e "${C}│${G} ──► Path: ${N}"
    read -r input_path
    input_path=$(clean_path "$input_path")
    if [ -z "$input_path" ]; then
        DOCUMENT_PATH="$DEFAULT_MLBB_DATA/Document.unity3d"
    else
        DOCUMENT_PATH="$input_path"
    fi

    echo -e "${C}├───${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Output Folder path to save files:${N}"
    echo -e "${C}│${N} ${B}    Default -> $DEFAULT_OUT_DIR${N}"
    echo -n -e "${C}│${G} ──► Folder: ${N}"
    read -r input_out
    input_out=$(clean_path "$input_out")
    if [ -z "$input_out" ]; then
        OUTPUT_DIR="$DEFAULT_OUT_DIR"
    else
        OUTPUT_DIR="$input_out"
    fi
    echo -e "${C}└──────────────────────────────────────────────────────────────┘${N}"

    mkdir -p "$OUTPUT_DIR" 2>/dev/null
    
    if [ ! -f "$DOCUMENT_PATH" ]; then
        echo -e "${R}[!] Warning: $DOCUMENT_PATH is not found currently.${N}"
    else
        SIZE=$(du -h "$DOCUMENT_PATH" 2>/dev/null | cut -f1)
        echo -e "${G}[✓] Target selection successful (Size: $SIZE)${N}"
    fi
    echo -e "${G}[✓] Output Folder set -> $OUTPUT_DIR${N}"
}

check_requirements() {
    if ! command -v python3 &>/dev/null; then
        echo -e "${R}[!] Python3 is not installed in the system. Please run 'pkg install python' in Termux first.${N}"
        return 1
    fi
    if [ ! -f "$DOCUMENT_PATH" ]; then
        echo -e "${R}[!] Target Document.unity3d file does not exist. Please check the path again.${N}"
        return 1
    fi
    return 0
}

do_extract_all() {
    setup_paths
    check_requirements || return
    echo -e "\n${Y}[*] Extracting all assets...${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" OUTPUT_DIR="$OUTPUT_DIR" python3 << 'EOF'
import sys, os, struct
magic = b'MLBB'
doc_path = os.environ.get('DOCUMENT_PATH')
out_dir = os.environ.get('OUTPUT_DIR')

with open(doc_path, 'rb') as f: data = f.read()
if data[:4] != magic: print('[!] Invalid Magic'); sys.exit(1)
count = struct.unpack_from('<I', data, 4)[0]
pos = 8; entries = []
for _ in range(count):
    nl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    name = data[pos:pos+nl].decode('utf-8', errors='replace'); pos += nl
    sz = struct.unpack_from('<I', data, pos)[0]; pos += 4
    off = struct.unpack_from('<I', data, pos)[0]; pos += 4
    entries.append((name, sz, off))
for name, sz, off in entries:
    abs_off = pos + off
    asset_data = data[abs_off:abs_off+sz]
    safe_name = name.replace(chr(92), '/').strip('/')
    out_path = os.path.join(out_dir, safe_name)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as out_f: out_f.write(asset_data)
    print(f'  [+] Extract: {name} ({sz:,} bytes)')
print('\n[✓] All assets extracted successfully!')
EOF
}

do_extract_xml_only() {
    setup_paths
    check_requirements || return
    echo -e "\n${Y}[*] Scanning and Extracting ALL XML files with Auto-Base64 Decoding...${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" OUTPUT_DIR="$OUTPUT_DIR" python3 << 'EOF'
import sys, os, struct, base64
magic = b'MLBB'
doc_path = os.environ.get('DOCUMENT_PATH')
out_dir = os.environ.get('OUTPUT_DIR')

with open(doc_path, 'rb') as f: data = f.read()
if data[:4] != magic: print('[!] Invalid Magic'); sys.exit(1)
count = struct.unpack_from('<I', data, 4)[0]
pos = 8; entries = []
for _ in range(count):
    nl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    name = data[pos:pos+nl].decode('utf-8', errors='replace'); pos += nl
    sz = struct.unpack_from('<I', data, pos)[0]; pos += 4
    off = struct.unpack_from('<I', data, pos)[0]; pos += 4
    entries.append((name, sz, off))
xml_entries = [(n, s, o) for n, s, o in entries if n.lower().endswith('.xml')]
if not xml_entries:
    print('\033[0;31m[!] Bundle ထဲမှာ ဘယ်လို XML file မှ ရှာမတွေ့ပါ။\033[0m')
    sys.exit(0)
print(f'[*] XML File စုစုပေါင်း ({len(xml_entries)}) ခုကို စတင်ထုတ်ယူနေပါတယ်...')
print('-' * 60)
extracted_count = 0
for name, sz, off in xml_entries:
    raw_bytes = data[pos+off : pos+off+sz]
    try:
        decoded_bytes = base64.b64decode(raw_bytes)
        decoded_text = decoded_bytes.decode('utf-8', errors='replace')
    except Exception:
        decoded_text = raw_bytes.decode('utf-8', errors='replace')
    safe_name = name.replace(chr(92), '/').strip('/')
    out_path = os.path.join(out_dir, safe_name)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as out_f:
        out_f.write(decoded_text)
    print(f'\033[0;32m  [✓] Extracted & Decoded -> {name}\033[0m')
    extracted_count += 1
print('-' * 60)
print(f'\033[1;32m[✓] ပြီးဆုံးပါပြီ။ XML file စုစုပေါင်း ({extracted_count}) ခုထုတ်ယူပြီးပါပြီ။\033[0m')
EOF
}

do_inject_battle() {
    setup_paths
    check_requirements || return
    echo -e "\n${C}┌─── [ INJECT SOURCE ] ────────────────────────────────────────┐${N}"
    echo -e "${C}│${N} ${Y}[?] Enter path of the (New/Modified) BattleSystemConfig.xml to inject:${N}"
    echo -n -e "${C}│${G} ──► XML Path: ${N}"
    read -r new_xml_path
    new_xml_path=$(clean_path "$new_xml_path")
    if [ ! -f "$new_xml_path" ]; then
        echo -e "${R}[!] The replacement XML file path is invalid or the file does not exist.${N}"
        return
    fi
    echo -e "${C}├───${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Output ZIP File Name (e.g., Mod_Config):${N}"
    echo -n -e "${C}│${G} ──► ZIP Name: ${N}"
    read -r zip_name
    zip_name=$(clean_path "$zip_name")
    if [ -z "$zip_name" ]; then
        zip_name="Document_Patched"
    fi

    echo -e "\n${Y}[*] Base64 encoding XML and injecting into Document.unity3d...${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" NEW_XML_PATH="$new_xml_path" ZIP_NAME="$zip_name" OUTPUT_DIR="$OUTPUT_DIR" python3 << 'EOF'
import sys, os, struct, base64, shutil, zipfile
magic = b'MLBB'
doc_path = os.environ.get('DOCUMENT_PATH')
new_xml_path = os.environ.get('NEW_XML_PATH')
zip_name = os.environ.get('ZIP_NAME')
out_dir = os.environ.get('OUTPUT_DIR')

with open(doc_path, 'rb') as f: data = f.read()
if data[:4] != magic: print('[!] Invalid Magic Header'); sys.exit(1)
count = struct.unpack_from('<I', data, 4)[0]
pos = 8; entries = []
for _ in range(count):
    nl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    name = data[pos:pos+nl].decode('utf-8', errors='replace'); pos += nl
    sz = struct.unpack_from('<I', data, pos)[0]; pos += 4
    off = struct.unpack_from('<I', data, pos)[0]; pos += 4
    entries.append({'name': name, 'size': sz, 'offset': off})
with open(new_xml_path, 'rb') as xml_f: xml_bytes = xml_f.read()
encoded_bytes = base64.b64encode(xml_bytes)
new_data_parts = []; new_entries = []; current_offset = 0
for e in entries:
    abs_off = pos + e['offset']
    if 'BattleSystemConfig.xml' in e['name']:
        asset_bytes = encoded_bytes
    else:
        asset_bytes = data[abs_off : abs_off + e['size']]
    new_data_parts.append(asset_bytes)
    new_entries.append({'name': e['name'], 'size': len(asset_bytes), 'offset': current_offset})
    current_offset += len(asset_bytes)
index_buf = bytearray()
index_buf += magic
index_buf += struct.pack('<I', len(new_entries))
for e in new_entries:
    nb = e['name'].encode('utf-8')
    index_buf += struct.pack('<I', len(nb)) + nb
    index_buf += struct.pack('<I', e['size'])
    index_buf += struct.pack('<I', e['offset'])
final_binary = bytes(index_buf) + b''.join(new_data_parts)
bak = doc_path + '.bak'
if not os.path.exists(bak):
    shutil.copy2(doc_path, bak)
with open(doc_path, 'wb') as f: f.write(final_binary)
print('[✓] Injection completed successfully!')
try:
    zip_filename = zip_name + '.zip' if not zip_name.endswith('.zip') else zip_name
    zip_out_path = os.path.join(out_dir, zip_filename)
    custom_arcname = os.path.join('dragon2017', 'assets', 'Document', 'android', os.path.basename(doc_path))
    with zipfile.ZipFile(zip_out_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(doc_path, arcname=custom_arcname)
    print(f'\x1b[0;32m[✓] Auto ZIP Success -> {zip_out_path}\x1b[0m')
except Exception as e:
    print(f'\x1b[0;31m[-] ZIP Creation Failed: {e}\x1b[0m')
EOF
}

do_list_assets() {
    setup_paths
    check_requirements || return
    echo -e "\n${Y}[*] Reading asset tables from index section...${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" python3 << 'EOF'
import struct, sys, os
magic = b'MLBB'
doc_path = os.environ.get('DOCUMENT_PATH')
with open(doc_path, 'rb') as f: data = f.read()
if data[:4] != magic: print('[!] Invalid Magic'); sys.exit(1)
count = struct.unpack_from('<I', data, 4)[0]
pos = 8
print(f'\n{"Index":<6} {"Asset Name":<50} {"Size (Bytes)":>15}')
print('-' * 75)
for i in range(count):
    nl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    name = data[pos:pos+nl].decode('utf-8', errors='replace'); pos += nl
    sz = struct.unpack_from('<I', data, pos)[0]; pos += 4
    off = struct.unpack_from('<I', data, pos)[0]; pos += 4
    print(f'{i:<6} {name:<50} {sz:>15,}')
print('-' * 75)
EOF
}

do_search_extract_xml() {
    setup_paths
    check_requirements || return
    echo -e "\n${C}┌─── [ SMART XML SEARCH & EXTRACT ] ───────────────────────────┐${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Code or Text (Keyword) to search:${N}"
    echo -n -e "${C}│${G} ──► Code/Keyword: ${N}"
    read -r search_query
    if [ -z "$search_query" ]; then
        echo -e "${R}[!] Cannot proceed because the search text is empty.${N}"
        return
    fi
    echo -e "\n${Y}[*] Scanning all XML assets inside bundle for target code...${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" SEARCH_QUERY="$search_query" OUTPUT_DIR="$OUTPUT_DIR" python3 << 'EOF'
import sys, os, struct, base64
magic = b'MLBB'
doc_path = os.environ.get('DOCUMENT_PATH')
search_query = os.environ.get('SEARCH_QUERY')
out_dir = os.environ.get('OUTPUT_DIR')

with open(doc_path, 'rb') as f: data = f.read()
if data[:4] != magic: print('[!] Invalid Magic'); sys.exit(1)
count = struct.unpack_from('<I', data, 4)[0]
pos = 8; entries = []
for _ in range(count):
    nl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    name = data[pos:pos+nl].decode('utf-8', errors='replace'); pos += nl
    sz = struct.unpack_from('<I', data, pos)[0]; pos += 4
    off = struct.unpack_from('<I', data, pos)[0]; pos += 4
    entries.append((name, sz, off))
xml_entries = [(n, s, o) for n, s, o in entries if n.lower().endswith('.xml')]
found_count = 0
query_lower = search_query.lower()
for name, sz, off in xml_entries:
    raw_bytes = data[pos+off : pos+off+sz]
    try: decoded_text = base64.b64decode(raw_bytes).decode('utf-8', errors='replace')
    except Exception: decoded_text = raw_bytes.decode('utf-8', errors='replace')
    if query_lower in decoded_text.lower():
        found_count += 1
        safe_name = name.replace(chr(92), '/').strip('/')
        out_path = os.path.join(out_dir, safe_name)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w', encoding='utf-8') as out_f: out_f.write(decoded_text)
        print(f'\033[0;32m[✓] Found & Extracted -> {name}\033[0m')
EOF
}

do_xml_editor() {
    setup_paths
    check_requirements || return
    echo -e "\n${C}┌─── [ SMART XML TAG EDITOR & INJECTOR ] ──────────────────────┐${N}"
    
    DOCUMENT_PATH="$DOCUMENT_PATH" python3 << 'EOF'
import os, re, base64, struct, sys, shutil
file_path = os.environ.get('DOCUMENT_PATH')
print('\n[*] Enter XML Block or Base64 string to inject/patch:')
lines = []
while True:
    try: line = input()
    except EOFError: break
    if line.strip() == 'DONE': break
    lines.append(line)
    if len(lines) == 1 and (not line.strip().startswith('<') or line.strip().endswith('/>')):
        if len(line.strip()) > 20 and ' ' not in line.strip(): break
target_value_input = '\n'.join(lines).strip()
if not target_value_input: sys.exit(1)
try:
    base64_input = str(target_value_input).strip()
    try:
        decoded_target_bytes = base64.b64decode(base64_input, validate=True)
        decoded_target_value = decoded_target_bytes.decode('utf-8')
    except Exception:
        decoded_target_value = base64_input
    tag_matcher = re.search(r'<\s*([a-zA-Z0-9_:-]+)', decoded_target_value)
    if not tag_matcher: raise Exception('Invalid XML structure.')
    tag_name = tag_matcher.group(1)
    with open(file_path, 'rb+') as f:
        magic = f.read(4)
        if magic != b'MLBB': raise Exception('Invalid Magic Bytes.')
        f.read(4)
        entries = []; current_pos = 8; f.seek(0, os.SEEK_END); file_length = f.tell(); f.seek(current_pos)
        while current_pos + 4 <= file_length:
            nl_bytes = f.read(4)
            if len(nl_bytes) < 4: break
            nl = struct.unpack('<I', nl_bytes)[0]
            if nl == 0 or nl > 512: break
            name = f.read(nl).decode('utf-8', errors='ignore')
            current_pos += 4 + nl
            size_pos = current_pos; offset_pos = current_pos + 4
            size = struct.unpack('<I', f.read(4))[0]
            offset = struct.unpack('<I', f.read(4))[0]
            current_pos += 8
            entries.append({'name': name, 'size_pos': size_pos, 'offset_pos': offset_pos, 'size': size, 'offset': offset})
        data_start = current_pos
        is_any_file_patched = False
        for i, entry in enumerate(entries):
            entry_name = entry['name']
            if entry_name and entry_name.lower().endswith('.xml'):
                old_size = entry['size']; old_off = entry['offset']
                f.seek(data_start + old_off)
                raw_data = f.read(old_size)
                is_battle_system = ('BattleSystemConfig.xml' == entry_name)
                try: working_xml_bytes = base64.b64decode(raw_data) if is_battle_system else raw_data
                except Exception: working_xml_bytes = raw_data
                xml_content = working_xml_bytes.decode('utf-8', errors='ignore')
                is_patched = False
                attr_pattern = re.compile(r'([a-zA-Z0-9_:-]+)="([^"]+)"')
                attrs = attr_pattern.findall(decoded_target_value)
                target_ids = []; main_attr_name = None
                for attr_name, attr_val in attrs:
                    if main_attr_name is None: main_attr_name = attr_name
                    if attr_name == main_attr_name: target_ids.append(attr_val)
                if main_attr_name and target_ids:
                    replace_count = 0; insert_position = -1
                    for id_val in target_ids:
                        dynamic_regex = rf'(?i)<{tag_name}[^>]*{re.escape(main_attr_name)}="{re.escape(id_val)}"[^>]*/>\s*'
                        line_pattern = re.compile(dynamic_regex)
                        match = line_pattern.search(xml_content)
                        if match:
                            if insert_position == -1: insert_position = match.start()
                            xml_content = line_pattern.sub('', xml_content)
                            replace_count += 1
                    if replace_count > 0 and insert_position != -1:
                        xml_content = xml_content[:insert_position] + decoded_target_value + '\n' + xml_content[insert_position:]
                        is_patched = True
                if is_patched:
                    print(f'[+] Patched target XML: {entry_name}')
                    is_any_file_patched = True
                    working_xml_bytes = xml_content.encode('utf-8')
                    final_processed_bytes = base64.b64encode(working_xml_bytes) if is_battle_system else working_xml_bytes
                    new_size = len(final_processed_bytes); size_delta = new_size - old_size
                    bak = file_path + '.bak'
                    if not os.path.exists(bak): shutil.copy2(file_path, bak)
                    f.seek(data_start + old_off + old_size); remaining_data = f.read()
                    f.seek(data_start + old_off); f.write(final_processed_bytes); f.write(remaining_data); f.truncate()
                    f.seek(entry['size_pos']); f.write(struct.pack('<I', new_size))
                    for j in range(i + 1, len(entries)):
                        entries[j]['offset'] += size_delta
                        f.seek(entries[j]['offset_pos']); f.write(struct.pack('<I', entries[j]['offset']))
                    break
        print('\n[+] Synchronization successful.')
except Exception as e: print(f'\n[-] Error occurred: {e}')
EOF
}

do_view_output() {
    if [ -z "$OUTPUT_DIR" ] || [ ! -d "$OUTPUT_DIR" ]; then
        OUTPUT_DIR=$DEFAULT_OUT_DIR
    fi
    echo -e "${B}\n========== [ Extracted Files inside Directory ] ==========${N}"
    if [ -d "$OUTPUT_DIR" ] && [ "$(ls -A "$OUTPUT_DIR")" ]; then
        ls -Rlh "$OUTPUT_DIR" | head -40
    else
        echo -e "${R}[!] No files have been extracted inside this folder yet.${N}"
    fi
}

do_clean_cache() {
    echo -n -e "${Y}[?] Do you want to clean old extracted files and cache? (y/n): ${N}"
    read -r ans
    if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
        rm -rf "$DEFAULT_OUT_DIR" "$BASE/temp_mlbb" 2>/dev/null
        echo -e "${G}[✓] Cache folder deleted and cleaned.${N}"
    else
        echo -e "${B}[*] Canceled.${N}"
    fi
}

do_compare_xml() {
    echo -e "\n${C}┌─── [ XML CODE DIFFERENCE DETECTOR ] ────────────────────────┐${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Original XML file path (xml 1):${N}"
    echo -n -e "${C}│${G} ──► Path: ${N}"
    read -r xml1_path
    xml1_path=$(clean_path "$xml1_path")
    echo -e "${C}├───${N}"
    echo -e "${C}│${N} ${Y}[?] Enter Modified/Target XML file path (xml 2):${N}"
    echo -n -e "${C}│${G} ──► Path: ${N}"
    read -r xml2_path
    xml2_path=$(clean_path "$xml2_path")
    echo -e "${C}└──────────────────────────────────────────────────────────────┘${N}"
    if [ ! -f "$xml1_path" ] || [ ! -f "$xml2_path" ]; then return; fi
    
    XML1_PATH="$xml1_path" XML2_PATH="$xml2_path" python3 << 'EOF'
import difflib, os
xml1_path = os.environ.get('XML1_PATH')
xml2_path = os.environ.get('XML2_PATH')

with open(xml1_path, 'r', encoding='utf-8', errors='ignore') as f1, open(xml2_path, 'r', encoding='utf-8', errors='ignore') as f2:
    diff = list(difflib.unified_diff(f1.readlines(), f2.readlines(), fromfile='XML 1', tofile='XML 2', lineterm=''))
for line in diff:
    if line.startswith('+') and not line.startswith('+++'): print(f'\033[0;32m{line}\033[0m')
    elif line.startswith('-') and not line.startswith('---'): print(f'\033[0;31m{line}\033[0m')
EOF
}

do_advanced_config_builder() {
    setup_paths
    check_requirements || return

    echo -e "\n${C}┌─── [ CONFIG BUILDER FEATURES ] ──────────────────────────────┐${N}"
    echo -e "${C}│  ${G}[1]${W} Drone View Only                                         ${C}│${N}"
    echo -e "${C}│  ${G}[2]${W} Drone View With Maphack                                 ${C}│${N}"
    echo -e "${C}│  ${G}[3]${W} Drone View With Damage Font                             ${C}│${N}"
    echo -e "${C}└──────────────────────────────────────────────────────────────┘${N}"
    echo -n -e "${Y}  Select Feature Module [1-3]: ${N}"
    read -r feat_choice

    if [ "$feat_choice" != "1" ] && [ "$feat_choice" != "2" ] && [ "$feat_choice" != "3" ]; then
        echo -e "${R}[!] Invalid selection.${N}"
        return
    fi

    echo -e "\n${C}┌─── [ PROCESS EXECUTION MODE ] ───────────────────────────────┐${N}"
    echo -e "${C}│  ${G}[1]${W} Custom Standalone Zoom Factor (e.g., 3.5, 5.0)          ${C}│${N}"
    echo -e "${C}│  ${G}[2]${W} Mass Batch Compilation Sequence (Generates 1x to 10x)    ${C}│${N}"
    echo -e "${C}└──────────────────────────────────────────────────────────────┘${N}"
    echo -n -e "${Y}  Select Execution Mode [1-2]: ${N}"
    read -r op_choice

    local zoom_val="0"
    if [ "$op_choice" = "1" ]; then
        echo -n -e "${Y}[?] Enter preferred custom Drone View multiplier value (>= 1.0): ${N}"
        read -r zoom_val
    fi

    echo -e "\n${Y}[*] Executing Advanced Python Compilation Engine...${N}"
    
    FEAT_CHOICE="$feat_choice" OP_CHOICE="$op_choice" ZOOM_VAL="$zoom_val" DOCUMENT_PATH="$DOCUMENT_PATH" OUTPUT_DIR="$OUTPUT_DIR" python3 << 'EOF'
import base64, os, re, struct, zipfile, shutil

feat_choice = os.environ.get('FEAT_CHOICE')
op_choice = os.environ.get('OP_CHOICE')
zoom_val = os.environ.get('ZOOM_VAL')
doc_path = os.environ.get('DOCUMENT_PATH')
out_dir = os.environ.get('OUTPUT_DIR')

BASE_CAMPS = [
    {'iId': 1, 'fPosX': 11.12, 'fPosY': -13.29, 'fPosZ': 11.06, 'fRotX': 38.57, 'fRotY': 44.90, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 18.0},
    {'iId': 2, 'fPosX': -11.12, 'fPosY': -13.29, 'fPosZ': -11.06, 'fRotX': 38.57, 'fRotY': -134.10, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 18.0},
    {'iId': 3, 'fPosX': -11.12, 'fPosY': -13.29, 'fPosZ': -11.06, 'fRotX': 38.57, 'fRotY': -134.10, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 18.0},
    {'iId': 4, 'fPosX': 0.40, 'fPosY': -10.98, 'fPosZ': 0.00, 'fRotX': 45.00, 'fRotY': 1.90, 'fRotZ': 1.10, 'fFov': 30.0, 'fScreenPtCastDis': 15.0},
    {'iId': 5, 'fPosX': -7.00, 'fPosY': -14.00, 'fPosZ': -10.75, 'fRotX': 57.00, 'fRotY': -180.00, 'fRotZ': 0.00, 'fFov': 30.0, 'fScreenPtCastDis': 15.0},
    {'iId': 6, 'fPosX': 9.47, 'fPosY': -36.00, 'fPosZ': -21.20, 'fRotX': 55.00, 'fRotY': -180.00, 'fRotZ': 0.00, 'fFov': 30.0, 'fScreenPtCastDis': 40.0},
    {'iId': 7, 'fPosX': -9.47, 'fPosY': -36.00, 'fPosZ': 21.20, 'fRotX': 55.00, 'fRotY': 0.00, 'fRotZ': 0.00, 'fFov': 30.0, 'fScreenPtCastDis': 40.0},
    {'iId': 8, 'fPosX': -6.54, 'fPosY': -17.00, 'fPosZ': -6.27, 'fRotX': 60.00, 'fRotY': -134.10, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 15.0},
    {'iId': 9, 'fPosX': 11.12, 'fPosY': -13.29, 'fPosZ': 11.06, 'fRotX': 38.57, 'fRotY': 44.90, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 40.0},
    {'iId': 10, 'fPosX': -11.12, 'fPosY': -13.29, 'fPosZ': -11.06, 'fRotX': 38.57, 'fRotY': -134.10, 'fRotZ': -0.07, 'fFov': 30.0, 'fScreenPtCastDis': 40.0}
]

def generate_drone_code(zoom_factor):
    step = zoom_factor - 1.0
    generated_lines = []
    for c in BASE_CAMPS:
        iId = c['iId']
        if iId in [1, 2, 3, 9, 10]:
            fPosX = c['fPosX'] * (1.0 + step * 0.1052)
            fPosY = c['fPosY'] + (step * -2.08)
            fPosZ = c['fPosZ'] * (1.0 + step * 0.1049)
            fRotX = c['fRotX'] + (step * 0.79)
        elif iId == 4:
            fPosX = c['fPosX'] * (1.0 + step * 0.105)
            fPosY = c['fPosY'] + (step * -1.72)
            fPosZ = c['fPosZ']
            fRotX = c['fRotX'] + (step * 0.79)
        elif iId == 5:
            fPosX = c['fPosX'] * (1.0 + step * 0.105)
            fPosY = c['fPosY'] + (step * -2.19)
            fPosZ = c['fPosZ'] * (1.0 + step * 0.105)
            fRotX = c['fRotX'] + (step * 0.79)
        elif iId in [6, 7]:
            fPosX = c['fPosX'] * (1.0 + step * 0.105)
            fPosY = c['fPosY'] + (step * -5.63)
            fPosZ = c['fPosZ'] * (1.0 + step * 0.105)
            fRotX = c['fRotX'] + (step * 0.79)
        elif iId == 8:
            fPosX = c['fPosX'] * (1.0 + step * 0.105)
            fPosY = c['fPosY'] + (step * -2.66)
            fPosZ = c['fPosZ'] * (1.0 + step * 0.105)
            fRotX = c['fRotX'] + (step * 0.79)
        fFov = c['fFov'] + (step * 1.58)
        fScreenPtCastDis = c['fScreenPtCastDis'] + (step * 1.42)
        line = '<SCameraCamp iId="{}" fPosX="{:.2f}" fPosY="{:.2f}" fPosZ="{:.2f}" fRotX="{:.2f}" fRotY="{:.2f}" fRotZ="{:.2f}" fFov="{:.1f}" fScreenPtCastDis="{:.1f}"/>'.format(iId, fPosX, fPosY, fPosZ, fRotX, c['fRotY'], c['fRotZ'], fFov, fScreenPtCastDis)
        generated_lines.append('      ' + line)
    return '\n'.join(generated_lines)

def patch_unity3d(local_file, patched_file, target_drone_val, mod_mode):
    try:
        with open(local_file, 'rb') as f:
            magic = f.read(4)
            if magic != b'MLBB': return False
            entry_count = struct.unpack('<I', f.read(4))[0]
            entries = []; target_idx = -1
            for i in range(entry_count):
                nl = struct.unpack('<I', f.read(4))[0]
                name = f.read(nl).decode('utf-8')
                size = struct.unpack('<I', f.read(4))[0]
                offset = struct.unpack('<I', f.read(4))[0]
                entries.append({'name': name, 'size': size, 'offset': offset})
                if 'battlesystemconfig.xml' in name.lower(): target_idx = i
            if target_idx == -1: return False
            data_offset = f.tell()
            target_entry = entries[target_idx]
            f.seek(data_offset + target_entry['offset'])
            xml_content = base64.b64decode(f.read(target_entry['size'])).decode('utf-8')
            
            flexible_cam_pattern = re.compile(r'(?s)<SCamera\s+iIndex="1">(.*?)</SCamera>')
            if flexible_cam_pattern.search(xml_content):
                replacement = '<SCamera iIndex="1">\n' + target_drone_val + '\n    </SCamera>'
                xml_content = flexible_cam_pattern.sub(replacement, xml_content, count=1)
            else: return False

            if mod_mode == '2':
                maphack_pattern = re.compile(r'<VBattleViewRange\s+[^>]*/>')
                maphack_code = '<VBattleViewRange fHero="60" fTower="60" fSoldier="7" />'
                xml_content = maphack_pattern.sub(maphack_code, xml_content) if maphack_pattern.search(xml_content) else xml_content.replace('<root>', '<root>\n  ' + maphack_code)
            elif mod_mode == '3':
                damage_pattern = re.compile(r'<AFlyTextAnimChanges\s+[^>]*Dict="SFlyTextAnim\.sOriName">')
                damage_code = '<AFlyTextAnimChanges sNewFont="FlyFont_CN" iNewNumFontSize="40" iNewIconFontSize="18" iNewMsgFontSize="24" iNewNumSpaceingX="-16" iNewFlyPreformanceLv="0" Dict="SFlyTextAnim.sOriName">'
                xml_content = damage_pattern.sub(damage_code, xml_content) if damage_pattern.search(xml_content) else xml_content.replace('<root>', '<root>\n  ' + damage_code + '\n  </AFlyTextAnimChanges>')

            if 'XoniTools' not in xml_content:
                xml_content = xml_content.replace('<root>', '<root>\n    XoniTools')

            final_base64_bytes = base64.b64encode(xml_content.encode('utf-8'))
            size_delta = len(final_base64_bytes) - target_entry['size']
            target_entry['size'] = len(final_base64_bytes)
            for i in range(target_idx + 1, len(entries)): entries[i]['offset'] += size_delta

            with open(patched_file, 'wb') as fos:
                fos.write(b'MLBB'); fos.write(struct.pack('<I', entry_count))
                for e in entries:
                    nb = e['name'].encode('utf-8')
                    fos.write(struct.pack('<I', len(nb)))
                    fos.write(nb)
                    fos.write(struct.pack('<I', e['size']))
                    fos.write(struct.pack('<I', e['offset']))
                f.seek(data_offset)
                fos.write(f.read(target_entry['offset']))
                fos.write(final_base64_bytes)
                f.seek(data_offset + target_entry['offset'] - size_delta + target_entry['size'])
                while True:
                    buf = f.read(65536)
                    if not buf: break
                    fos.write(buf)
        return True
    except Exception as e:
        print('❌ Error: {}'.format(e))
        return False

def create_structured_zip(source_file, output_zip_name):
    zip_path_structure = 'dragon2017/assets/Document/android/Document.unity3d'
    try:
        target_dir = os.path.dirname(output_zip_name)
        if target_dir and not os.path.exists(target_dir):
            os.makedirs(target_dir, exist_ok=True)
            
        with zipfile.ZipFile(output_zip_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
            zipf.write(source_file, arcname=zip_path_structure)
        print('  [📦] Saved -> {}/{}'.format(os.path.basename(target_dir), os.path.basename(output_zip_name)))
        return True
    except Exception as e: return False

def process_single_patch(zoom_value, local_file, mod_mode, folder_name):
    feature_dir = os.path.join(out_dir, folder_name)
    patched_file = os.path.join(out_dir, 'Document_patched.unity3d')
    output_zip = os.path.join(feature_dir, '{}_{}x.zip'.format(folder_name, zoom_value))
    
    dynamic_code = generate_drone_code(zoom_value)
    if patch_unity3d(local_file, patched_file, dynamic_code, mod_mode):
        create_structured_zip(patched_file, output_zip)
        if os.path.exists(patched_file): os.remove(patched_file)

folder_map = {'1': 'Drone_Only', '2': 'Drone_Maphack', '3': 'Drone_Damage'}
target_folder = folder_map[feat_choice]

if op_choice == '1':
    try:
        z_val = float(zoom_val)
        if z_val >= 1.0: process_single_patch(z_val, doc_path, feat_choice, target_folder)
        else: print('⚠️ Multiplier must be >= 1.0')
    except ValueError: print('❌ Structural parsing error.')
else:
    print('🚀 Automating batch build (1x to 10x) into {} folder...'.format(target_folder))
    for i in range(1, 11):
        process_single_patch(float(i), doc_path, feat_choice, target_folder)
    print('✅ Batch jobs completed inside target Sub-Folder.')
EOF
}

# ========== CLEAN & MODERN BOX UI MENU ==========
while true; do
    clear
    echo -e "${C}┌──────────────────────────────────────────────┐${N}"
    echo -e "${C}│ ${W}    __  𝑴𝑳𝑩𝑴 𝑫𝒐𝒄𝒖𝒎𝒆𝒏𝒕.𝒖𝒏𝒊𝒕𝒚𝟑𝒅 𝑬𝒅𝒊𝒕𝒐𝒓       ${C}│${N}"
    echo -e "${C}│ ${M}            Created by @xoni_l               ${C}│${N}"
    echo -e "${C}├──────────────────────────────────────────────┤${N}"
    echo -e "${C}│                                              │${N}"
    echo -e "${C}│  ${G}[01]${W} Extract All Raw Assets                 ${C}│${N}"
    echo -e "${C}│  ${G}[02]${W} Extract All XML Only (Auto-Decode)      ${C}│${N}"
    echo -e "${C}│  ${G}[03]${W} Inject Modified BattleSystemConfig    ${C}│${N}"
    echo -e "${C}│  ${G}[04]${W} List Asset Table Entries Only          ${C}│${N}"
    echo -e "${C}│  ${G}[05]${W} Search Code & Extract Matching XMLs   ${C}│${N}"
    echo -e "${C}│  ${G}[06]${W} Smart XML Tag Editor & Injector       ${C}│${N}"
    echo -e "${C}│  ${G}[07]${W} View Extracted Output Files            ${C}│${N}"
    echo -e "${C}│  ${G}[08]${W} Clean Extracted & Cache Folders        ${C}│${N}"
    echo -e "${C}│  ${G}[09]${W} XML Code Difference Detector (New)    ${C}│${N}"
    echo -e "${C}│  ${Y}[10]${M} Advanced Config Builder Matrix (New)  ${C}│${N}"
    echo -e "${C}│  ${R}[11]${W} Exit Program                           ${C}│${N}"
    echo -e "${C}│                                              │${N}"
    echo -e "${C}└──────────────────────────────────────────────┘${N}"
    echo -n -e "${Y}  Select Option [1-11]: ${N}"
    read -r choice
    
    case $choice in
        1|01) do_extract_all ;;
        2|02) do_extract_xml_only ;;
        3|03) do_inject_battle ;;
        4|04) do_list_assets ;;
        5|05) do_search_extract_xml ;;
        6|06) do_xml_editor ;;
        7|07) do_view_output ;;
        8|08) do_clean_cache ;;
        9|09) do_compare_xml ;;
        10) do_advanced_config_builder ;;
        11) echo -e "\n${G}[✓] Goodbye - XONI${N}\n"; exit 0 ;;
        *) echo -e "${R}[!] Invalid Option! Please select valid range 1 to 11.${N}" ;;
    esac
    echo -e "\n${B}Press [Enter] to return to menu...${N}"
    read -r _
done
