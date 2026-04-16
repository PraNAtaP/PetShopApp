import os
import re

def fix_imports():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if not file.endswith('.dart'): continue
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()

            new_content = content
            
            # depth diff calculation logic? Much easier: just replace any relative import that reaches 'core', 'models', 'services'
            # with an absolute-style package import, or correct relative import.
            # Easiest way in flutter is changing relative parent imports to package imports:
            # import '../../core/theme/app_colors.dart' -> import 'package:petshopapp/core/theme/app_colors.dart'
            
            new_content = re.sub(r'import\s+\'(?:\.\./)+core/', "import 'package:petshopapp/core/", new_content)
            new_content = re.sub(r'import\s+\'(?:\.\./)+models/', "import 'package:petshopapp/models/", new_content)
            new_content = re.sub(r'import\s+\'(?:\.\./)+services/', "import 'package:petshopapp/services/", new_content)
            new_content = re.sub(r'import\s+\'(?:\.\./)+ui/', "import 'package:petshopapp/ui/", new_content)

            # Fix router.dart to package imports too if needed (it already works but no harm)
            
            if new_content != content:
                print(f"Fixed {filepath}")
                with open(filepath, 'w') as f:
                    f.write(new_content)

if __name__ == '__main__':
    fix_imports()
