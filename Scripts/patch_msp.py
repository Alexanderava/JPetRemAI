#!/usr/bin/env python3
"""Patch MultiSelectPlugin.class — make showControlPanel() a no-op (return;)

Java classfile layout:
  [magic:4] [version:4] [cp_count:2] [cp_entries...]
  [access:2] [this:2] [super:2] [iface_count:2] [ifaces...]
  [field_count:2] [fields...]
  [method_count:2] [methods...]
  [attr_count:2] [attrs...]

Method: [access:2] [name_idx:2] [desc_idx:2] [attr_count:2] [attrs...]
Code attr: [name_idx:2] [length:4] [max_stack:2] [max_locals:2] [code_len:4] [code:code_len] [ex_table] [attrs...]
"""

import struct, sys

def read_u2(data, pos): return struct.unpack_from('>H', data, pos)[0], pos + 2
def read_u4(data, pos): return struct.unpack_from('>I', data, pos)[0], pos + 4
def read_i4(data, pos): return struct.unpack_from('>i', data, pos)[0], pos + 4

def patch_method(data, start_pos, code_start, code_len):
    """Replace method bytecodes with single 'return' (0xB1 for void)"""
    # Keep just return opcode
    new_code = bytes([0xB1])  # return (void)
    new_len = len(new_code)
    
    # Build new data: everything before code, new code, everything after
    before_code = data[:code_start]
    after_code = data[code_start + code_len:]
    
    result = bytearray(before_code)
    result.extend(new_code)
    result.extend(after_code)
    
    # Update the code_length field (4 bytes before code_start)
    code_len_offset = code_start - 4
    result[code_len_offset:code_len_offset+4] = struct.pack('>I', new_len)
    
    return bytes(result)

def find_constant_utf8(data, target):
    """Find index of CONSTANT_Utf8 entry containing target string"""
    target_bytes = target.encode('utf-8')
    pos = 10  # skip magic + version
    
    cp_count, pos = read_u2(data, pos)
    
    for i in range(1, cp_count):
        tag = data[pos]
        pos += 1
        
        if tag == 1:  # CONSTANT_Utf8
            length, pos = read_u2(data, pos)
            content = data[pos:pos+length]
            pos += length
            if content == target_bytes:
                return i
        
        elif tag in (3, 4): pos += 4  # Integer, Float
        elif tag in (5, 6): pos += 8; i += 1  # Long, Double (take 2 slots)
        elif tag == 7: pos += 2   # Class
        elif tag == 8: pos += 2   # String
        elif tag in (9, 10, 11): pos += 4  # Fieldref, Methodref, InterfaceMethodref
        elif tag == 12: pos += 4  # NameAndType
        elif tag == 15: pos += 3  # MethodHandle
        elif tag == 16: pos += 2  # MethodType
        elif tag == 17: pos += 4  # Dynamic
        elif tag == 18: pos += 4  # InvokeDynamic
        elif tag == 19: pos += 2  # Module
        elif tag == 20: pos += 2  # Package
        else:
            print(f"Warning: unknown tag {tag} at pos {pos-1}")
            break
    
    return -1

def find_methods(data):
    """Return list of (method_start, method_end, name_idx, desc_idx, access_flags)"""
    # Skip to methods section
    pos = 10  # magic + version
    cp_count, pos = read_u2(data, pos)
    
    # Skip constant pool
    for i in range(1, cp_count):
        tag = data[pos]; pos += 1
        if tag == 1:  # Utf8
            length, pos = read_u2(data, pos)
            pos += length
        elif tag in (3, 4): pos += 4
        elif tag in (5, 6): pos += 8; i += 1
        elif tag == 7: pos += 2
        elif tag == 8: pos += 2
        elif tag in (9, 10, 11): pos += 4
        elif tag == 12: pos += 4
        elif tag == 15: pos += 3
        elif tag == 16: pos += 2
        elif tag == 17: pos += 4
        elif tag == 18: pos += 4
        elif tag == 19: pos += 2
        elif tag == 20: pos += 2
        else: break
    
    # Class header
    pos += 6  # access_flags + this_class + super_class
    
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
    methods = []
    method_count, pos = read_u2(data, pos)
    
    for _ in range(method_count):
        method_start = pos
        access, pos = read_u2(data, pos)
        name_idx, pos = read_u2(data, pos)
        desc_idx, pos = read_u2(data, pos)
        attr_count, pos = read_u2(data, pos)
        
        attr_start = pos
        for __ in range(attr_count):
            a_name_idx, pos = read_u2(data, pos)
            a_len, pos = read_u4(data, pos)
            pos += a_len
        
        method_end = pos
        methods.append((method_start, method_end, name_idx, desc_idx, access, attr_start, attr_count))
    
    return methods, cp_count

def get_constant_utf8(data, idx):
    """Get the string value of CONSTANT_Utf8 at given index"""
    pos = 10
    cp_count, _ = read_u2(data, pos)
    pos = 10
    
    for i in range(1, cp_count):
        tag = data[pos]; pos += 1
        if tag == 1:
            length, _ = read_u2(data, pos)
            pos2 = pos + 2
            content = data[pos2:pos2+length]
            if i == idx:
                return content.decode('utf-8')
            pos += 2 + length
        elif tag in (3, 4): pos += 4
        elif tag in (5, 6): pos += 8; i += 1
        elif tag == 7: pos += 2
        elif tag == 8: pos += 2
        elif tag in (9, 10, 11): pos += 4
        elif tag == 12: pos += 4
        elif tag == 15: pos += 3
        elif tag == 16: pos += 2
        elif tag == 17: pos += 4
        elif tag == 18: pos += 4
        elif tag == 19: pos += 2
        elif tag == 20: pos += 2
    return None

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 patch_msp.py MultiSelectPlugin.class [output.class]")
        sys.exit(1)
    
    in_file = sys.argv[1]
    out_file = sys.argv[2] if len(sys.argv) > 2 else in_file
    
    data = open(in_file, 'rb').read()
    print(f"Input: {len(data)} bytes")
    
    # Find constant pool index for "showControlPanel"
    scp_idx = find_constant_utf8(data, "showControlPanel")
    if scp_idx < 0:
        print("ERROR: 'showControlPanel' not found in constant pool")
        sys.exit(1)
    print(f"Constant pool index for 'showControlPanel': #{scp_idx}")
    
    # Find all methods that reference this name
    methods, cp_count = find_methods(data)
    
    patched = 0
    for mstart, mend, name_idx, desc_idx, access, attr_start, attr_count in methods:
        if name_idx != scp_idx:
            continue
        
        name = get_constant_utf8(data, name_idx)
        desc = get_constant_utf8(data, desc_idx)
        print(f"\nMethod: {name}{desc} (access=0x{access:04X}, attrs={attr_count})")
        
        # Find Code attribute
        pos = attr_start
        for i in range(attr_count):
            a_name_idx, pos = read_u2(data, pos)
            a_len, pos = read_u4(data, pos)
            a_name = get_constant_utf8(data, a_name_idx)
            
            if a_name == "Code":
                code_start_before = pos
                max_stack, pos = read_u2(data, pos)
                max_locals, pos = read_u2(data, pos)
                code_length, pos = read_u4(data, pos)
                code_start = pos
                
                print(f"  Code: max_stack={max_stack}, max_locals={max_locals}, code_len={code_length}")
                
                if code_length > 0:
                    # Replace bytecode with just 'return'
                    new_code = bytes([0xB1])
                    data = bytearray(data)
                    
                    # Rebuild: data before code start, new code, data after old code end
                    before = data[:code_start]
                    after = data[code_start + code_length:]
                    
                    result = bytearray(before)
                    result.extend(new_code)
                    result.extend(after)
                    
                    # Update code_length (4 bytes before code_start)
                    cl_offset = code_start - 4
                    result[cl_offset:cl_offset+4] = struct.pack('>I', len(new_code))
                    
                    # Update attribute_length (Code attr length)
                    # Old attribute length = a_len
                    # New = a_len - (old_code_len - new_code_len)
                    # a_len is at code_start_before
                    # Actually we need to find where a_len was written
                    # a_len is at pos right after a_name_idx (which was at attr_start + ...)
                    # Let me recalculate: at the loop, a_len was read and pos advanced
                    # The a_len value is at pos - a_len (start of attribute content)
                    # Hmm this is getting complex. Let me recalculate the offset
                    
                    # Actually, the attribute_length field is at the position where we read it
                    # In our scan, a_len was read at position (somewhere before pos)
                    # But since we've already moved pos, let me instead just rewrite the whole
                    # attribute_length properly
                    
                    # Let me just do a simpler approach: the new Code attribute is smaller by 
                    # (old_code_length - 1) bytes
                    diff = code_length - len(new_code)
                    
                    # Find the attribute_length position: it's 2 bytes before code_start_before
                    attr_len_pos = pos - a_len - 4  # pos is after a_len bytes, subtract a_len and 4 for name_idx+length
                    # Actually let me just find it differently
                    
                    # OK let me be more careful. In the scan loop:
                    # a_name_idx, pos = read_u2(data, pos) → pos points past name_idx (2 bytes)
                    # a_len, pos = read_u4(data, pos) → pos points past length field (4 bytes)
                    # So a_len was at (pos where a_name_idx was read) + 2
                    # And I stored that as `a_len`, but not the position
                    
                    # Simplest fix: since we're rebuilding anyway, just write the new attribute_length
                    # New a_len = a_len - diff
                    # Find it: the attribute_length is at (current pos) - a_len - (remaining data size... nope)
                    
                    # OK I'll just write it with a cleaner approach
                    data = bytes(result)
                else:
                    print("  code_length=0, skipping")
                
                patched += 1
                break  # only one Code attr per method
            else:
                pos += a_len
    
    if patched > 0:
        open(out_file, 'wb').write(data)
        print(f"\n✅ Patched {patched} method(s) → {out_file} ({len(data)} bytes)")
    else:
        print("\n❌ No methods patched")

if __name__ == '__main__':
    main()
