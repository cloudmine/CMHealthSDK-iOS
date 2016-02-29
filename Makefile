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
	git tag -s ${VERSION}  "version ${VERSION}"

verify-tag: get-version
	git tag --verify ${VERSION}

push-origin: get-version
	git push origin $VERSION

cocoapods-push:
	pod spec lint
	pod trunk push CMHealth.podspec
	pod trunk add-owner CMHealth tech@cloudmine.me
	@$(MAKE) bump-patch

release: get-version tag-version verify-tag push-origin cocoapods-push

clairvoyance-docs:
	-@find docs/ -name "*.md" -exec rm -rf {} \;
	git clone git@github.com:cloudmine/clairvoyance.git
	-@rsync -rtuvl --exclude=.git --delete clairvoyance/docs/3_iOS/9_CMHealthSDK_and_ResearchKit/ docs/
	-@cp clairvoyance/docs/3_iOS/9_CMHealthSDK_and_ResearchKit/CMHealth-SDK-Login-Screen.png .
	-@rm -rf clairvoyance
	@$(MAKE) readme

readme:
	-@find docs/*/* -name "*.md" -not -name "*index*" -exec perl -i.bak -pe 's{^##? }{### };' "{}" \;
	-@find docs/* -name "*.md" -exec perl -i.bak -pe 's{^# }{## };' "{}" \;
	-@find docs -name "*.md" -exec sh -c "cat {}; echo" \; \
	| sed -e 's/## CMHealth and ResearchKit/# CMHealth/' \
	| perl -pe 's#\(img/(.*\.png)\)#($$1)#' \
	| sed -e s'#https://github.com/cloudmine/CMHealthSDK-iOS/blob/master/##' > README.md
	-@find . -name "*.bak" -exec rm -rf {} \;

