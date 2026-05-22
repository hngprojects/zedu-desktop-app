import os
import re

def process_file(filepath):
    # Skip major barrel files
    if filepath.endswith('core.dart') or filepath.endswith('features.dart') or filepath.endswith('app.dart'):
        # Just check if it's purely exports, wait, core.dart is a barrel file. We can skip the whole core/ and features/ barrel files if we want, but it's easier to just skip specific ones or pure export files.
        pass

    with open(filepath, 'r') as f:
        content = f.read()

    # Skip files that are "part of"
    if 'part of ' in content:
        return

    # Check if this is a pure export file (a barrel file)
    lines = content.split('\n')
    is_pure_barrel = True
    for line in lines:
        l = line.strip()
        if l and not l.startswith('export') and not l.startswith('//') and not l.startswith('import'):
            is_pure_barrel = False
            break
            
    if is_pure_barrel:
        return

    imports_to_keep = set()
    other_lines = []
    
    in_imports = True
    for line in lines:
        if line.startswith('import '):
            if 'dart:' in line:
                imports_to_keep.add(line)
        elif line.startswith('export ') and in_imports:
            # wait, export should be kept
            imports_to_keep.add(line)
        else:
            if line.strip() != '':
                in_imports = False
            if not in_imports:
                other_lines.append(line)

    # Reconstruct file
    new_imports = [
        "import 'package:zedu/core/core.dart';",
        "import 'package:zedu/features/features.dart';"
    ]
    
    # Sort dart imports
    dart_imports = sorted([i for i in imports_to_keep if i.startswith("import 'dart:")])
    
    # Sort exports
    exports = sorted([i for i in imports_to_keep if i.startswith("export ")])

    final_lines = []
    if dart_imports:
        final_lines.extend(dart_imports)
        final_lines.append("")
        
    final_lines.extend(new_imports)
    final_lines.append("")
    
    if exports:
        final_lines.extend(exports)
        final_lines.append("")

    # Join other lines but remove leading empty lines
    while other_lines and other_lines[0].strip() == '':
        other_lines.pop(0)
        
    final_content = '\n'.join(final_lines + other_lines)
    
    if content != final_content:
        with open(filepath, 'w') as f:
            f.write(final_content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done formatting imports!")
