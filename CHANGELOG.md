## 0.3.0 Release Notes

### Added
- Added input validation with automatic re-prompts.
  - Yes/No questions now accept only `yes`, `y`, `true`, or `t` for **Yes**, and `no`, `n`, `false`, or `f` for **No**. Invalid input prompts the user to try again.
  - Questions with **Yes / 90 Days / No** options now accept:
    - `yes`, `y`, `true`, or `t` for **Yes**
    - `90` or `ninety` for **90 Days**
    - `no`, `n`, `false`, or `f` for **No**
    Invalid input prompts the user to try again.
  - URL responses must be valid URLs. Invalid input prompts the user to enter a valid URL.
  - Open-ended responses now require a non-empty answer. Empty responses prompt the user to try again.
- Added debug logging for the `upload_google_data_safety` action to include the response body in logs.

### Changed
- Updated the `googleauth` gem dependency to allow versions greater than `1.8.1`.

### Fixed
- Added the missing in-app search history data collection question.
- Corrected the `.gemspec` filename.
- Fixed an issue where missing directories were not created automatically.
- Sanitized CSV input to mitigate [OWASP CSV Injection](https://owasp.org/www-community/attacks/CSV_Injection).