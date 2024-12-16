# Fastlane google_data_safety Plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-google_data_safety)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-google_data_safety`, add it to your project by running:

```bash
fastlane add_plugin google_data_safety
```

## About google_data_safety

Google safety data plugin help with automation of data safety form on Google Play Console. Review [Google policy data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) for more information about the form.

## Actions

### upload_google_data_safety

Uploads Google data safety csv file to Google Play Console.

#### 2 Examples

```ruby
upload_google_data_safety(
    csv_file: "data_safety_export.csv",
    package_name: "my.package.name",
    json_key: "key.json"
)
```

```ruby
upload_google_data_safety(
    csv_content: "Question ID (machine readable),Response ID (machine readable),Response value,Answer requirement,Human-friendly question label\n ...",
    package_name: "my.package.name",
    json_key_data: "..."
)
```

#### Parameters

| Key | Description |
| --- | ----------- |
| json_key_data | The raw service account JSON data used to authenticate with Google |
| json_key | The path to a file containing service account JSON, used to authenticate with Google |
| package_name | The package name of the application to use |
| csv_file | The path to a file containing Google data safety csv |
| csv_content | The raw csv data used for Google data safety |

### prompt_create_data_safety_csv

Prompt user questions about data usage within Android app.
**Does not allow for non interactive mode**.

#### Example

```ruby
prompt_create_data_safety_csv(
  csv_file: "google_data_safety.csv"
)
```

#### Parameters

| Key | Description |
| --- | ----------- |
| csv_file | The path to save csv file for upload to Google Play Console |

#### Issue reporting

For Issues on incorrect CSV file, please get a screenshot of manual import of csv file issues.

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository. Any issue specific to generating CSV file, please upload a screenshot of CSV file error and all of the question prompt answers.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
