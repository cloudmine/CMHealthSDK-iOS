before attempting a release you must set up a gpg key, which you can then use to sign the release.  useful tools for generating and maintaining your key can be found here

* [GPGKeychain for OSX](https://gpgtools.org/)
* [keybase.io](https://keybase.io/)

once you have your key, you can set it as the signing key for future releases:

```
git config --global user.signingkey YOURKEYFINGERPRINT
```

now you can continue with the release process

1. bump version in `CMHealth.podspec`
```
vi CMHealth.podspec
```
2. tag the release
```
git tag -s 0.2.1 -m "version 0.2.1"
```
2. verify the tag
```
git tag --verify 0.2.1
```
3. push the tag to github
```
git push origin 0.2.1
```
4. lint the pod
```
pod spec lint
```
5. push the pod to CocoaPods
```
6. pod --allow-warnings trunk push CMHealth.podspec
```
7. grant the entire team access
```
pod trunk add-owner CMHealth tech@cloudmine.me
```
