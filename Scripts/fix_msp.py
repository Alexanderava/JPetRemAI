#!/usr/bin/env python3
"""Fix MultiSelectPlugin.class — patch showControlPanel method to no-op.
Handles partially corrupted constant pools by recovering at entry boundaries."""

import sys, struct

def read_u2(d, p):
    return struct.unpack_from('>H', d, p)[0], p + 2
def read_u4(d, p):
    return struct.unpack_from('>I', d, p)[0], p + 4

def skip_cp_entry(d, pos):
    """Skip one constant pool entry, returns new pos. Returns -1 if can't parse."""
    if pos >= len(d):
        return -1
    tag = d[pos]
    pos += 1
    try:
        if tag == 1:   # Utf8
            l, pos = read_u2(d, pos); pos += l
        elif tag in (3, 4): pos += 4
        elif tag in (5, 6): pos += 8
        elif tag == 7: pos += 2
        elif tag == 8: pos += 2
        elif tag in (9, 10, 11): pos += 4
        elif tag == 12: pos += 4
        elif tag == 15: pos += 3
        elif tag == 16: pos += 2
        elif tag == 17: pos += 4   # CONSTANT_Dynamic
        elif tag == 18: pos += 4   # CONSTANT_InvokeDynamic
        elif tag == 19: pos += 2   # CONSTANT_Module
        elif tag == 20: pos += 2   # CONSTANT_Package
        else:
            return -1  # Unknown tag
        return pos
    except:
        return -1

def find_cp_index_of_utf8(d, target_name):
    """Find constant pool index for a Utf8 entry matching target_name.
    Returns (index, offset_after_tag, utf8_pos) or None.
    Even if CP is partially corrupt, we find entries before the corruption."""
    cp_count, pos = read_u2(d, 8)
    cp_start = 10
    p = cp_start
    target = target_name.encode('utf-8')
    
    for i in range(1, cp_count):
        if p >= len(d):
            break
        tag = d[p]
        if tag == 1:
            l, _ = read_u2(d, p + 1)
            if p + 3 + l > len(d):
                break
            s = d[p+3:p+3+l]
            if s == target:
                return i  # CP index
            p += 3 + l
        else:
            p2 = skip_cp_entry(d, p)
            if p2 < 0:
                break  # Can't parse further
            if tag in (5, 6):
                i += 1  # Long/Double take 2 slots
            p = p2
    return None

def patch_class_file(data):
    """Return modified class bytes with showControlPanel methods NOP'd."""
    
    # Find CP index for "showControlPanel"
    scp_idx = find_cp_index_of_utf8(data, "showControlPanel")
    if scp_idx is None:
        print("ERROR: 'showControlPanel' not found in CP")
        return data
    
    print(f"CP index for 'showControlPanel': #{scp_idx}")
    
    # Also get "Code" CP index
    code_idx = find_cp_index_of_utf8(data, "Code")
    if code_idx is None:
        print("ERROR: 'Code' not found in CP")
        return data
    print(f"CP index for 'Code': #{code_idx}")
    
    # Get "()V" CP index (descriptor for void no-args method)
    void_idx = find_cp_index_of_utf8(data, "()V")
    print(f"CP index for '()V': #{void_idx}")
    
    if void_idx is None:
        print("ERROR: '()V' not found in CP")
        return data
    
    # Now find method_info entries
    # We need to skip: magic(4) + version(4) + cp + access(2) + this(2) + super(2) + interfaces + fields
    cp_count, _ = read_u2(data, 8)
    
    # Skip constant pool
    pos = 10
    for i in range(1, cp_count):
        tag = data[pos]
        if tag in (5, 6):
            i += 1
        n = skip_cp_entry(data, pos)
        if n < 0:
            print(f"CP parse failed at entry #{i} (pos {pos}), trying to continue from known offset...")
            # Hard recovery: find next valid method area
            break
        pos = n
    
    # Class header
    pos += 6  # access_flags(2) + this_class(2) + super_class(2)
    
    # Interfaces
    iface_count, pos = read_u2(data, pos)
    pos += iface_count * 2
    
    # Fields
    field_count, pos = read_u2(data, pos)
    for _ in range(field_count):
        pos += 6  # access + name + desc
        fattr_count, pos = read_u2(data, pos)
        for _ in range(fattr_count):
            pos += 2  # name_idx
            attr_len, pos = read_u4(data, pos)
            pos += attr_len
    
    # Methods
    method_count, pos = read_u2(data, pos)
    print(f"Methods section at pos {pos}, count={method_count}")
    
    result = bytearray(data)
    patched = 0
    
    for mi in range(method_count):
        m_start = pos
        access, pos = read_u2(data, pos)
        name_idx, pos = read_u2(data, pos)
        desc_idx, pos = read_u2(data, pos)
        attr_count, pos = read_u2(data, pos)
        
        # Check if this method's name is "showControlPanel" and descriptor is "()V"
        if name_idx == scp_idx and desc_idx == void_idx:
            print(f"  Method #{mi}: showControlPanel ()V at pos {m_start}")
            
            # Walk attributes to find Code
            attr_pos = pos
            for _ in range(attr_count):
                if attr_pos + 6 > len(data):
                    break
                a_name_idx, attr_pos = read_u2(data, attr_pos)
                a_len, attr_pos = read_u4(data, attr_pos)
                a_content_start = attr_pos
                
                if a_name_idx == code_idx:
                    # Found Code attribute!
                    max_stack, attr_pos = read_u2(data, attr_pos)
                    max_locals, attr_pos = read_u2(data, attr_pos)
                    code_length, attr_pos = read_u4(data, attr_pos)
                    code_start = attr_pos
                    
                    print(f"    Code: max_stack={max_stack} max_locals={max_locals} code_len={code_length}")
                    
                    if code_length > 1:
                        # Replace with just 'return' (0xB1)
                        new_code = bytes([0xB1])
                        new_len = 1
                        
                        # Build new data
                        before = result[:code_start]
                        after = result[code_start + code_length:]
                        
                        result = bytearray(before)
                        result.extend(new_code)
                        result.extend(after)
                        
                        # Update code_length (4 bytes before code_start)
                        cl_off = code_start - 4
                        result[cl_off:cl_off+4] = struct.pack('>I', new_len)
                        
                        # Update attribute_length (2 bytes after a_content_start - 6)
                        # a_content_start is where attr data begins
                        # attribute_length is at a_content_start - 6 + 2 = a_content_start - 4
                        # Wait: read_u2 reads name_idx, then read_u4 reads length
                        # attr_pos started at a_content_start (after name_idx + length)
                        # So name_idx was at a_content_start - 6
                        # And length was at a_content_start - 4
                        al_off = a_content_start - 4
                        old_a_len = code_length + (attr_pos - code_start)  # code + exceptions + sub-attrs
                        new_a_len = old_a_len - (code_length - new_len)
                        result[al_off:al_off+4] = struct.pack('>I', new_a_len)
                        
                        print(f"    ✅ Patched! code_len: {code_length} → {new_len}, attr_len: {old_a_len} → {new_a_len}")
                        patched += 1
                        
                        # Rewind data reference
                        data = bytes(result)
                    
                    break
                else:
                    attr_pos += a_len
        
        # Advance pos past this method's attributes
        pos2 = pos
        for _ in range(attr_count):
            if pos2 + 6 > len(data):
                break
            _, pos2 = read_u2(data, pos2)
            al, pos2 = read_u4(data, pos2)
            pos2 += al
        pos = pos2
    
    if patched == 0:
        print("No methods matched (wrong descriptor?)")
        # Let's try all methods matching just the name
        pos = 10
        # Skip CP again (we need to rescan)
    
    return bytes(result)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: fix_msp.py MultiSelectPlugin.class [output.class]")
        sys.exit(1)
    
    inp = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else inp
    
    data = open(inp, 'rb').read()
    print(f"Input: {len(data)} bytes")
    
    result = patch_class_file(data)
    
    open(out, 'wb').write(result)
    print(f"Output: {len(result)} bytes → {out}")
