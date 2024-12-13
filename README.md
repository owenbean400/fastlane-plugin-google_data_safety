# Fastlane google_data_safety Plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-google_data_safety)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-google_data_safety`, add it to your project by running:

```bash
fastlane add_plugin google_data_safety
```

## About google_data_safety

Google safety data sheet help with automation of data safety form on Google Play Console. Review [Google policy data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) for more information about the form.

## upload_google_data_safety

### 2 Examples

```ruby
upload_google_data_safety(
    csv_file: "data_safety_export.csv",
    package_name: "my.package.name",
    json_key: "key.json"
)
```

```ruby
upload_google_data_safety(
    csv_content: "uestion ID (machine readable),Response ID (machine readable),Response value,Answer requirement,Human-friendly question label\n ...",
    package_name: "my.package.name",
    json_key_data: "..."
)
```

### Parameters

| Key | Description |
| --- | ----------- |
| json_key_data | The raw service account JSON data used to authenticate with Google |
| json_key | The path to a file containing service account JSON, used to authenticate with Google |
| package_name | The package name of the application to use |
| csv_file | The path to a file containing Google data safety csv |
| csv_content | The raw csv data used for Google data safety |

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
