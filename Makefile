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
