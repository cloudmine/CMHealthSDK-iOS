# Contributing to CMHealth

Thank you for your desire to make CMHealth better.  The Engineering Team at CloudMine
is looking forward to working with you!

## Support


## Reporting Bugs in CMHealth

The [public GitHub issue tracker](https://github.com/cloudmine/CMHealthSDK-iOS/issues) is
the preferred channel for bug reports, features requests and submitting pull requests.


## Contributing

Please adhere to the following process when contributing to CMHealth

1. [Fork](https://help.github.com/fork-a-repo/) the project, clone your fork,
   and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone git@github.com:<your github username>/CMHealthSDK-iOS.git
   # Navigate to the newly cloned directory
   cd CMHealthSDK-iOS
   # Assign the original repo to a remote called "cloudmine"
   git remote add cloudmine https://github.com/cloudmine/CMHealthSDK-iOS.git
   ```

 2. If you cloned a while ago, get the latest changes from `cloudmine`

    ```bash
    git checkout master
    git fetch cloudmine master
    git merge cloudmine/master
    ```

3. Install the SDK dependencies using [CocoaPods](https://cocoapods.org/) and
   open the project

   ```bash
   # Navigate to the Example project directory; this is only used as a test target
   cd Example
   # Run the CocoaPods installer
   pod install
   # Launch XCode with the workspace
   open CMHealth.xcworkspace
   ```

4. Configure the integration test credentials

    ```bash
    # Copy the template file
    cp Tests/CMHTest-Secrets.h-Template Tests/CMHTest-Secrets.h
    # Open secrets file and edit the CMHTestsAppId & CMHTestsAPIKey constants
    open Tests/CMHTest-Secrets.h
    ```

5. Ensure the tests are running: in XCode select the `CMHealth-Example` target
   and press `⌘-u`. All tests should pass; if they do not, review your
   configuration.

6. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

7. Commit your changes in logical chunks. Be sure existing tests still pass,
   and include unit or integration tests for your feature or bug-fix as
   appropriate. Pull Requests without tests may not be merged until they are
   included.

8. Locally merge (or rebase) the upstream development branch into your topic branch:

   ```bash
   git fetch cloudmine master
   git merge cloudmine/master
   ```

9. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

10. [Open a Pull Request](https://help.github.com/articles/using-pull-requests/)
    with a clear title and description against the `master` branch.


## Have Fun!

Coding should be fun.  We hope you enjoy both using and contributing to CMHealth.


## License

By contributing your code, you agree to license your contribution under the
current CMHealth license [MIT License](LICENSE).
