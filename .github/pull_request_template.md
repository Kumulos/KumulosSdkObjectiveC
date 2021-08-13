### Description of Changes

(briefly outline the reason for changes, and describe what's been done)

### Breaking Changes

-   None

### Release Checklist

Prepare:

-   [ ] Detail any breaking changes. Breaking changes require a new major version number
-   [ ] Check `pod lib lint` passes
-   [ ] Check all targets (iOS, extension, macOS, statics) build
-   [ ] Install branch via Cocoapods into empty project & verify can import SDK (only needed if adding/removing files)

Bump versions in:

-   [ ] `Sources/Kumulos+Stats.m`
-   [ ] `KumulosSdkObjectiveC.podspec`
-   [ ] `KumulosSdkObjectiveCExtension.podspec`
-   [ ] All relevant build targets
-   [ ] `README.md`

Release:

-   [ ] Squash and merge to master
-   [ ] Delete branch once merged
-   [ ] Create tag from master matching chosen version
-   [ ] Run `pod trunk push` to publish to CocoaPods

Post Release:

Update docs site with correct version number references

- [ ] https://docs.kumulos.com/developer-guide/sdk-reference/ios/
- [ ] https://docs.kumulos.com/getting-started/integrate-app/

Update changelog:

- [ ] https://docs.kumulos.com/developer-guide/sdk-reference/ios/#changelog
