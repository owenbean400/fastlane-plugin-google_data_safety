## 0.3.0 Release Notes

- Added input validation with reprompt
  - Yes or no answers must be "yes", "y", "true", or "t" for yes; and "no", "n", "false", or "f" for no. Other input cause reprompt to user for answer.
  - Question for yes, yes 90 days, and no require "yes", "y", "true", or "t" for yes; "90" or "ninty" for 90 days; and "no", "n", "false", or "f" for no. Other input cause reprompt to user for answer.
  - URL answers must be follow URL convention. Other input cause reprompt to user for answer.
  - Open answers requires a non empty answer. Empty answer cause reprompt to user for answer.
- Fix missing in-app search history data collection question
- Fix .gemspec file name
- Fix unknown directory by creating missing directories
- CSV input sanitation (OWASP CSV Injection)[https://owasp.org/www-community/attacks/CSV_Injection]
- Update googleauth gem dependency to expand to greater than 1.8.1 version
- Add debug on upload_google_data_safety action for response body output in logs