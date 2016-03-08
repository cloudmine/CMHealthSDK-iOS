bump-patch:
	@perl -i.bak -pe 's/(\d+)(")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CMHealth.podspec 
	@rm -f CMHealth.podspec.bak
	@$(MAKE) get-version

bump-minor:
	@perl -i.bak -pe 's/(\d+)(\.\d+")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CMHealth.podspec 
	@rm -f CMHealth.podspec.bak
	@$(MAKE) get-version

bump-major:
	@perl -i.bak -pe 's/(\d+)(\.\d+\.\d+")$$/($$1+1).$$2/e if m/version\s+=\s+"\d+\.\d+\.\d+"$$/;' CMHealth.podspec 
	@rm -f CMHealth.podspec.bak
	@$(MAKE) get-version

get-version:
	$(eval VERSION := $(shell perl -lne 'print $$1 if m/^\s+s.version.*"(.*)"$$/' CMHealth.podspec))
	@echo ${VERSION}

tag-version: get-version
	git tag -s ${VERSION} -m "version ${VERSION}"

verify-tag: get-version
	git tag --verify ${VERSION}

push-tag-to-origin: get-version
	git push origin ${VERSION}

cocoapods-push:
	pod spec lint
	pod trunk push CMHealth.podspec
	pod trunk add-owner CMHealth tech@cloudmine.me

stage-next-release: bump-patch
	git commit -m"bump to ${VERSION}" CMHealth.podspec
	git push origin master

docs:
	-@find docs/ -name "*.md" -exec rm -rf {} \;
	git clone git@github.com:cloudmine/clairvoyance.git
	-@rsync -rtuvl --exclude=.git --delete clairvoyance/docs/03_ResearchKit/ docs/
	-@cp clairvoyance/app/img/CMHealth-SDK-Login-Screen.png .
	-@rm -rf clairvoyance
	@$(MAKE) readme
.PHONY: docs

readme:
	-@find docs/*/* -name "*.md" -not -name "*index*" -exec perl -i.bak -pe 's{^##? }{### };' "{}" \;
	-@find docs/* -name "*.md" -exec perl -i.bak -pe 's{^# }{## };' "{}" \;
	-@find docs -name "*.md" -exec sh -c "cat {}; echo" \; \
	| sed -e 's/## CMHealth and ResearchKit/# CMHealth/' \
	| perl -pe 's#\(img/(.*\.png)\)#($$1)#' \
	| sed -e s'#https://github.com/cloudmine/CMHealthSDK-iOS/blob/master/##' > README.md
	-@find . -name "*.bak" -exec rm -rf {} \;

open:
	cd Example; pod install
	open Example/CMHealth.xcworkspace

create-signatures: get-version
	curl https://github.com/cloudmine/CMHealthSDK-iOS/archive/${VERSION}.tar.gz -o CMHealthSDK-iOS-${VERSION}.tar.gz 1>/dev/null 2>&1
	curl https://github.com/cloudmine/CMHealthSDK-iOS/archive/${VERSION}.zip -o CMHealthSDK-iOS-${VERSION}.zip 1>/dev/null 2>&1
	gpg --armor --detach-sign CMHealthSDK-iOS-${VERSION}.tar.gz
	gpg --verify CMHealthSDK-iOS-${VERSION}.tar.gz.asc CMHealthSDK-iOS-${VERSION}.tar.gz
	-@rm -f CMHealthSDK-iOS-${VERSION}.tar.gz
	gpg --armor --detach-sign CMHealthSDK-iOS-${VERSION}.zip
	gpg --verify CMHealthSDK-iOS-${VERSION}.zip.asc CMHealthSDK-iOS-${VERSION}.zip
	-@rm -f CMHealthSDK-iOS-${VERSION}.zip

# only for the brave...
release: get-version tag-version verify-tag push-tag-to-origin cocoapods-push create-signatures stage-next-release

