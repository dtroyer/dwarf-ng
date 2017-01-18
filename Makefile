# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
# Copyright (c) 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Destination branch for build
BUILD_BRANCH=local

# Branches to be merged into local build
LOCAL_BRANCHES=

VENV_DIR := .dwarf

tox:
	tox

pep8 pylint tests coverage:
	tox -e $@

clean:
	@find . \( -name .tox -o -name .git \) -prune -o \
		\( -name '*~' -o -name '*.pyc' \) -type f -print | \
		xargs rm -f
	@rm -r dwarf.egg-info 2>/dev/null || :
	@rm -f .coverage

deepclean: clean
	@rm -rf .tox 2>/dev/null || :

tgz: VERSION = $(shell git tag | sort -n | tail -1 | tr -d 'v')
tgz:
	git archive --format=tar --prefix=dwarf-$(VERSION)/ main | \
		gzip -9 > ../dwarf-$(VERSION).tar.gz

release:
	[ -n "$${v}" ] || \
	    ( echo "+++ Usage: make release v=<VERSION>" ; false )
	[ "$${v#v}" != "$${v}" ] || \
	    ( echo "+++ Version string must start with 'v'" ; false )
	# Update ChangeLog
	( \
	    echo $${v} ; \
	    prev=$$(cat ChangeLog | head -1) ; \
	    git --no-pager log --no-merges --format='  * %s' $${prev}..  ; \
	    echo ; \
	    cat ChangeLog ; \
	) > ChangeLog.new
	mv ChangeLog.new ChangeLog
	# Update debian/changelog.in
	#debian/bin/update-changelog.in $${v#v}
	# Update snap/snapcraft.yaml
	#sed -i -e "s/^version: .*$$/version: '$${v#v}'/" snap/snapcraft.yaml
	# commit and tag
	git add ChangeLog
	git commit -m "$${v}"
	git tag -m "$${v}" $${v}

debian:
	! [ -d build-debian ] || rm -rf build-debian
	mkdir build-debian
	git archive --format=tar HEAD | ( cd build-debian ; tar -xf - )
	cd build-debian && \
	    ./debian/bin/create-changelog && \
	    dpkg-buildpackage
	rm -rf build-debian

.PHONY: tox pep8 pylint tests coverage clean deepclean tgz release debian

build:
	git checkout main
	git branch -D $(BUILD_BRANCH) || true
	git checkout -b $(BUILD_BRANCH)
	for i in $(LOCAL_BRANCHES); do \
		echo "Merging $$i"; \
		git checkout $$i; \
		git checkout -; \
		git merge --no-edit $$i; \
	done


run:
	sudo su -s /bin/sh -c './bin/dwarf -s' dwarf

init:
	pid=$$(ps -ef | grep './bin/dwarf' | grep sudo | grep -v grep | \
	       awk '{ print $$2 }') ; \
	    if [ "$${pid}" != "" ] ; then \
	        sudo kill $${pid} && \
	        sleep 5 ; \
	    fi
	sudo su -s /bin/sh -c './bin/dwarf-manage db-delete' dwarf
	sudo su -s /bin/sh -c './bin/dwarf-manage db-init' dwarf

$(VENV_DIR):
	virtualenv $(VENV_DIR)

venv: $(VENV_DIR)
	$(VENV_DIR)/bin/pip install -r requirements.txt
	$(VENV_DIR)/bin/pip install .

venv-dev: $(VENV_DIR)
	$(VENV_DIR)/bin/pip install -e .

vrun: venv
	sudo su -s /bin/sh -c '$(VENV_DIR)/bin/dwarf -s' dwarf

vinit: venv
	pid=$$(ps -ef | grep '$(VENV_DIR)/bin/dwarf' | grep sudo | grep -v grep | \
	       awk '{ print $$2 }') ; \
	    if [ "$${pid}" != "" ] ; then \
	        sudo kill $${pid} && \
	        sleep 5 ; \
	    fi
	sudo su -s /bin/sh -c '$(VENV_DIR)/bin/dwarf-manage db-delete' dwarf
	sudo su -s /bin/sh -c '$(VENV_DIR)/bin/dwarf-manage db-init' dwarf
