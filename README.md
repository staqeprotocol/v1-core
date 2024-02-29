# Staqe Protocol

```
Ran 10 tests for test/Staqe.t.sol:StaqeTest
[PASS] testFuzz_AddReward(uint256) (runs: 256, μ: 892484, ~: 892475)
[PASS] testFuzz_AddReward_Errors(bytes32) (runs: 256, μ: 607183, ~: 607326)
[PASS] testFuzz_EditPool(bytes32) (runs: 256, μ: 555989, ~: 556413)
[PASS] testFuzz_LaunchPool(address,bytes32) (runs: 256, μ: 352910, ~: 353105)
[PASS] testFuzz_LaunchPool_Errors(address) (runs: 256, μ: 305593, ~: 305941)
[PASS] testFuzz_Stake(uint256) (runs: 256, μ: 1705191, ~: 1705187)
[PASS] testFuzz_Stake_Errors(uint256) (runs: 256, μ: 390561, ~: 390561)
[PASS] testFuzz_Unstake(uint256) (runs: 256, μ: 1197276, ~: 1197272)
[PASS] testFuzz_Unstake_Errors(uint256) (runs: 256, μ: 1234558, ~: 1234556)
[PASS] test_ClaimRewards() (gas: 4566321)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 447.21ms (2.19s CPU time)
```

| contracts/StaqeDeploy.sol:StaqeDeploy contract |                 |        |        |        |         |
|------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                | Deployment Size |        |        |        |         |
| 2872897                                        | 13132           |        |        |        |         |
| Function Name                                  | min             | avg    | median | max    | # calls |
| addReward                                      | 44566           | 125481 | 168478 | 214079 | 14      |
| claimRewards                                   | 105400          | 120591 | 117068 | 138854 | 8       |
| editPool                                       | 29612           | 32582  | 32728  | 35307  | 6       |
| getPool                                        | 1855            | 7188   | 1855   | 17855  | 9       |
| getRewards                                     | 3348            | 3348   | 3348   | 3348   | 3       |
| getStakes                                      | 1806            | 3664   | 4284   | 4284   | 4       |
| getTotalPools                                  | 668             | 668    | 668    | 668    | 1       |
| launchPool                                     | 34871           | 144561 | 158681 | 181321 | 23      |
| stake                                          | 29263           | 134934 | 128520 | 246721 | 84      |
| unstake                                        | 47052           | 95125  | 54814  | 189437 | 8       |