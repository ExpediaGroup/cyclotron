# Contributing to Cyclotron

If you'd like to contribute a feature or bug fix, you can [fork](https://help.github.com/articles/fork-a-repo/) Cyclotron, commit your changes, & [send a pull request](https://help.github.com/articles/using-pull-requests/).

Refer to [EXTENDING.md](EXTENDING.md) for technical information about adding Data Sources, Widgets, etc.

## Issues

Please search the issue tracker before submitting a new issue, in case your issue has already been reported or fixed.

When opening an issue, please include as much information as possible, including the version of the code, browser version, any JavaScript errors, etc.

## Tests

Before submitting a pull request that makes changes to the website, please rerun the automated tests to ensure they still work:

    gulp test

Pull requests to add more tests are always welcome!

## Coding Guidelines

In addition to the following guidelines, please follow the established code style and formatting:

- **Spacing**:<br>
  Use four spaces for indentation. No tabs.

- **Naming**:<br>
  Keep variable & method names concise & descriptive.<br>

- **Quotes**:<br>
  Single-quoted strings are preferred to double-quoted strings; however, please use a double-quoted string if the value contains a single-quote character to avoid unnecessary escaping.

- **Comments**:<br>
  Cyclotron-svc uses /* */ for comments rather than //.  Cyclotron-site is written in CoffeeScript, so it uses # for comments.

- **CoffeeScript**:<br>
  Cyclotron-site is written in CoffeeScript, and as such uses many of its conventions.  However, optional elements like parentheses and return statements should be included when omitting them may lead to confusion.
