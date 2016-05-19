# About These Scripts

mainly ask @kdomanski

## Tagger

Creates a release by tagging all necessary images on quay.io and updating the repo that tells Soul that an update is available.

1. get Token for this app for each organization from [quay.io](https://quay.io/organization/protonetinc/application/AAJ2R0ICT52931V8S1GN?tab=gen-token) with the »Read/Write to any accessible repositories« permission.
2. `export TOKEN_PLATFORM="XXX"`
3. `export TOKEN_PROTONET="YYY"`
4. get current build number for the specific branch [from the CI](https://travis-ci.com/protonet/german-shepherd/branches)
5. test run `./tagger.sh -b <BRANCH_NUMBER>`
6. if the test run looks good: `./tagger.sh -b <BRANCH_NUMBER> --commit`