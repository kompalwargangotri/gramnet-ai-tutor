import argostranslate.package
import argostranslate.translate

# Update package index
argostranslate.package.update_package_index()

# Get available packages
available_packages = argostranslate.package.get_available_packages()

# Install English ↔ Hindi
for pkg in available_packages:
    if pkg.from_code == "en" and pkg.to_code == "hi":
        print("Installing en → hi")
        argostranslate.package.install_from_path(pkg.download())

    if pkg.from_code == "hi" and pkg.to_code == "en":
        print("Installing hi → en")
        argostranslate.package.install_from_path(pkg.download())

print(" Translation models installed!")
