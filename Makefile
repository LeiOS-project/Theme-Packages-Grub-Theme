# LeiOS Digital Clock Plasmoid — build, package, install and test helpers.
# All destructive commands validate their target variables to prevent
# accidental damage if a variable is empty.

PACKAGE_NAME := leios.theme.plasmoids.digitalclock
PLASMOID_ID  := dev.leios.theme-packages.plasmoids.digitalclock
DEB_BUILD_OUTPUT_DIR := deb-build

# Guard macro: abort if a variable is empty.
require_var = $(if $(strip $1),,$(error Required variable is empty: $2))

.PHONY: all clean distclean package install update dev-install test publish-apt

all: package

# Safe cleanup used by debhelper: only removes generated files that are not
# the final build output directory. That directory is kept because this target
# is called by dh_auto_clean while the package is still being built.
clean:
	@:$(call require_var,$(DEB_BUILD_OUTPUT_DIR),DEB_BUILD_OUTPUT_DIR)
	dh_clean || true
	find . -name '*.deb' -delete
	find . -name '*.changes' -delete
	find . -name '*.buildinfo' -delete
	find . -name '*.dsc' -delete
	find . -name '*.tar.xz' -delete
	find . -name '*.tar.gz' -delete

# Full cleanup including build output and APT repo directory.
distclean: clean
	@:$(call require_var,$(DEB_BUILD_OUTPUT_DIR),DEB_BUILD_OUTPUT_DIR)
	rm -rf "$(DEB_BUILD_OUTPUT_DIR)"

package:
	@:$(call require_var,$(PACKAGE_NAME),PACKAGE_NAME)
	@:$(call require_var,$(DEB_BUILD_OUTPUT_DIR),DEB_BUILD_OUTPUT_DIR)
	mkdir -p "$(DEB_BUILD_OUTPUT_DIR)"
	dpkg-buildpackage -us -uc -b
	mv ../$(PACKAGE_NAME)_*.deb ../$(PACKAGE_NAME)_*.changes ../$(PACKAGE_NAME)_*.buildinfo "$(DEB_BUILD_OUTPUT_DIR)/" 2>/dev/null || true

install: package
	@:$(call require_var,$(PACKAGE_NAME),PACKAGE_NAME)
	@:$(call require_var,$(DEB_BUILD_OUTPUT_DIR),DEB_BUILD_OUTPUT_DIR)
	sudo apt-get install -y $(DEB_BUILD_OUTPUT_DIR)/$(PACKAGE_NAME)_*.deb || \
		(sudo apt-get install -f -y && sudo apt-get install -y $(DEB_BUILD_OUTPUT_DIR)/$(PACKAGE_NAME)_*.deb)

update: package
	@:$(call require_var,$(PACKAGE_NAME),PACKAGE_NAME)
	@:$(call require_var,$(DEB_BUILD_OUTPUT_DIR),DEB_BUILD_OUTPUT_DIR)
	sudo apt-get install --only-upgrade -y $(DEB_BUILD_OUTPUT_DIR)/$(PACKAGE_NAME)_*.deb || \
		(sudo apt-get install -f -y && sudo apt-get install --only-upgrade -y $(DEB_BUILD_OUTPUT_DIR)/$(PACKAGE_NAME)_*.deb)

dev-install:
	@:$(call require_var,$(PLASMOID_ID),PLASMOID_ID)
	if kpackagetool6 -g -t Plasma/Applet -s $(PLASMOID_ID) >/dev/null 2>&1; then \
		sudo kpackagetool6 -g -t Plasma/Applet -u ./src; \
	else \
		sudo kpackagetool6 -g -t Plasma/Applet -i ./src; \
	fi
	-systemctl --user stop plasma-plasmashell.service
	rm -rf ~/.cache/plasma* ~/.cache/*.kcache ~/.cache/plasmashell/qmlcache/
	-systemctl --user start plasma-plasmashell.service

test:
	@:$(call require_var,$(PLASMOID_ID),PLASMOID_ID)
	plasmawindowed $(PLASMOID_ID)
