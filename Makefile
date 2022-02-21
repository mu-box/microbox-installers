SHELL := /bin/bash
INSTALLER_VERSION := 2
MICROBOX_VERSION := 2
VIRTUALBOX_VERSION := 6.1.32
VIRTUALBOX_REVISION := 149290
DOCKER_MACHINE_VERSION := 0.16.2

.PHONY: mac windows mac-bundle windows-bundle clean clean-mac clean-mac-bundle clean-windows clean-windows-bundle publish publish-beta urls

default: mac windows mac-bundle windows-bundle arch centos debian generic-linux
	@true

clean: clean-mac clean-mac-bundle clean-windows-bundle clean-windows clean-arch clean-centos clean-debian clean-generic-linux
	for i in $$(docker ps --format {{.Names}}); do docker stop $$i; done
	for i in $$(docker ps -a --format {{.Names}}); do docker rm $$i; done
	for i in $$(docker images -f "dangling=true" --format {{.ID}}); do docker rmi $$i; done

clean-all: clean
	for i in $$(docker images --format {{.ID}}); do docker rmi $$i; done

mac: clean-mac certs
	./script/build-mac ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

mac-bundle: clean-mac-bundle virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg certs
	./script/build-mac-bundle ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-OSX.dmg"

windows: clean-windows certs
	./script/build-windows ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

windows-bundle: clean-windows-bundle virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe certs
	./script/build-windows-bundle ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe:
	mkdir -p virtualbox
	curl -fsSL -o virtualbox/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe "http://download.virtualbox.org/virtualbox/${VIRTUALBOX_VERSION}/VirtualBox-${VIRTUALBOX_VERSION}-${VIRTUALBOX_REVISION}-Win.exe"

centos: clean-centos
	./script/build-centos ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

debian: clean-debian
	./script/build-debian ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

arch: clean-arch
	./script/build-arch ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

generic-linux: clean-generic-linux
	./script/build-generic-linux ${INSTALLER_VERSION} ${MICROBOX_VERSION} ${VIRTUALBOX_VERSION} ${VIRTUALBOX_REVISION} ${DOCKER_MACHINE_VERSION}

clean-mac:
	if [[ -f dist/mac/Microbox.pkg ]]; then rm -f dist/mac/Microbox.pkg; fi

clean-mac-bundle:
	if [[ -f dist/mac/MicroboxBundle.pkg ]]; then rm -f dist/mac/MicroboxBundle.pkg; fi

clean-windows:
	if [[ -f dist/windows/MicroboxSetup.exe ]]; then rm -f dist/windows/MicroboxSetup.exe; fi

clean-windows-bundle:
	if [[ -f dist/windows/MicroboxBundleSetup.exe ]]; then rm -f dist/windows/MicroboxBundleSetup.exe; fi

clean-centos:
	if [[ -f dist/linux/microbox-${INSTALLER_VERSION}-1.x86_64.rpm ]]; then rm -f dist/linux/microbox-${INSTALLER_VERSION}-1.x86_64.rpm; fi

clean-debian:
	if [[ -f dist/linux/microbox_${INSTALLER_VERSION}_amd64.deb ]]; then rm -f dist/linux/microbox_${INSTALLER_VERSION}_amd64.deb; fi

clean-arch:
	if [[ -f dist/linux/microbox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz ]]; then rm -f dist/linux/microbox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz; fi

clean-generic-linux:
	if [[ -f dist/linux/microbox-${INSTALLER_VERSION}.tar.gz ]]; then rm -f dist/linux/microbox-${INSTALLER_VERSION}.tar.gz; fi

certs:
	mkdir -p certs
	aws s3 sync \
		s3://private.microbox.cloud/certs \
		certs/ \
		--region us-west-2

publish:
	aws s3 sync \
		dist/ \
		s3://tools.microbox.cloud/installers/v${INSTALLER_VERSION} \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1
	# aws configure set preview.cloudfront true
	# aws cloudfront create-invalidation \
	# 	--distribution-id E1O0D0A2DTYRY8 \
	# 	--paths /installers/v${INSTALLER_VERSION}/mac/Microbox.pkg /installers/v${INSTALLER_VERSION}/mac/MicroboxBundle.pkg \
	# 	/installers/v${INSTALLER_VERSION}/windows/MicroboxSetup.exe /installers/v${INSTALLER_VERSION}/windows/MicroboxBundleSetup.exe \
	# 	/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1.x86_64.rpm /installers/v${INSTALLER_VERSION}/linux/microbox_${INSTALLER_VERSION}_amd64.deb \
	# 	/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz /installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}.tar.gz \

publish-beta:
	aws s3 sync \
		dist/ \
		s3://tools.microbox.cloud/installers/beta \
		--grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
		--region us-east-1

urls:
	@echo S3:
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/mac/Microbox.pkg
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/mac/MicroboxBundle.pkg
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/windows/MicroboxSetup.exe
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/windows/MicroboxBundleSetup.exe
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1.x86_64.rpm
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/linux/microbox_${INSTALLER_VERSION}_amd64.deb
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz
	@echo https://s3.amazonaws.com/tools.microbox.cloud/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}.tar.gz
	# @echo CloudFront:
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/mac/Microbox.pkg
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/mac/MicroboxBundle.pkg
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/windows/MicroboxSetup.exe
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/windows/MicroboxBundleSetup.exe
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1.x86_64.rpm
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/microbox_${INSTALLER_VERSION}_amd64.deb
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}-1-x86_64.pkg.tar.xz
	# @echo https://d1ormdui8qdvue.cloudfront.net/installers/v${INSTALLER_VERSION}/linux/microbox-${INSTALLER_VERSION}.tar.gz
