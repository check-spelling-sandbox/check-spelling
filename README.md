# Spelling tools

## Overview

Everyone makes typos. This includes people writing documentation and comments,
but it also includes programmers naming variables, functions, apis, classes,
and filenames.

Often, programmers will use `InitialCapitalization`, `camelCase`,
`ALL_CAPS`, or `IDLCase` when naming their things. When they do this, it makes
it much harder for naive spelling tools to recognize misspellings, and as such,
with a really high false-positive rate, people don't tend to enable spellchecking
at all.

This repository's tools are capable of tolerating all of those variations.
Specifically, [w](https://github.com/jsoref/spelling/blob/master/w) understands
enough about how programmers name things that it can split the above conventions
into word-like things for checking against a dictionary.

## Spell Checker GitHub Actions

[![Spell checking](https://github.com/check-spelling/check-spelling/workflows/Spell%20checking/badge.svg?branch=master)](https://github.com/check-spelling/check-spelling/actions?query=workflow:"Spell+checking"+branch:master)

* [Configuration](https://github.com/check-spelling/check-spelling/wiki/Configuration)
  * [Workflow variables](https://github.com/check-spelling/check-spelling/wiki/Configuration#workflow-variables)
  * [Workflows](https://github.com/check-spelling/check-spelling/wiki/Configuration%3A-Workflows)
  * [Files](https://github.com/check-spelling/check-spelling/wiki/Configuration#Files)
* [Possible features](https://github.com/check-spelling/check-spelling/wiki/Possible-features)
are listed on the [wiki](https://github.com/check-spelling/check-spelling/wiki/)
* [Historical information](https://github.com/jsoref/spelling#overview)

### Sample output

#### Comment as seen in a PR

![github action comment](images/check-spelling-comment.png)

#### Comment as seen in a commit

![github action annotation](images/check-spelling-annotation.png)

#### GitHub Action Run log

![github action log](images/check-spelling-log.png)

### Basic Configuration

#### Variables

| Variable | Description |
| ------------- | ------------- |
| [config](#config) | directory with config files |
| [dictionary_url](#dictionary_url) | url for primary dictionary |
| [dictionary_version](#dictionary_version) | version of primary dictionary |
| GITHUB_TOKEN | Secret used to retrieve your code and comment on PRs/commits. |

##### config

Default: `.github/actions/spelling`

In this directory, you can place [files](#Files) to influence the spell checker.

##### dictionary_url

If you don't define a dictionary using [dictionary](#dictionary) files,
the spell checker will retrieve a dictionary. You can provide a different url
if you have a preferred base. The default includes a variable (`$DICTIONARY_VERSION`)
for a [version](#dictionary_version).

This feature is new with 0.0.17.

##### dictionary_version

If [dictionary_url](#dictionary_url) includes (`$DICTIONARY_VERSION`),
you can override the default version.

Over time, the default version will probably change.
See [feature: versioned
dictionaries](https://github.com/check-spelling/check-spelling/wiki/Feature:-Versioned-dictionaries)
for more information.

#### Files

Note that each of the below items can either be a file w/ a `.txt` suffix,
or a directory, where each file with a `.txt` suffix will be merged together.

| Variable | Description |
| ------------- | ------------- |
| [advice](#advice) | This allows you to supplement the comment. |
| [allow](#allow) | This allows you to supplement the dictionary. |
| [dictionary](#dictionary) | This allows you to replace the dictionary. |
| [excludes](#excludes) | This allows you to skip checking files/directories. |
| [expect](#expect) | This defines the list of words in the repository that aren't in the dictionary. |
| [only](#only) | This allows you to limit checking to certain files/directories. |
| [patterns](#patterns) | This allows you to define patterns of acceptable strings. |
| [reject](#reject) | This allows you to remove items from the default dictionary. |

##### advice

This adds a supplemental portion to the comment
posted to github. It's freeform. You can use
it to explain how contributors should decide
where to put new entries.

##### allow

This allows you to add supplemental words to
the dictionary without relacing the core dictionary.

##### dictionary

This replaces the [default dictionary](https://github.com/check-spelling/check-spelling/raw/dictionary/dict.txt).
One word per line.

If you want to include the default dictionary,
place it into the directory next to your own.

##### excludes

This file contains Perl regular expressions.
Generally, one regular expression per line.
They are merged using an `OR` (`|`).

Files matching these patterns will be skipped.

See the wiki for [excludes examples](
https://github.com/check-spelling/check-spelling/wiki/Configuration-Examples:-excludes)

Lines that start with `#` will be ignored.

##### expect

This contains of expected "words" that aren't in the dictionary, one word per line.
Expected words that are not otherwise present in the corpus will be suggested for removal,
but will not trigger a failure.

Words that are present (i.e. not matched by the excludes file) in the repository
and which are not listed in the expect list will trigger a failure as part of
**[push](#push)**,
**[pull_request_target](#pull_request_target)**,
and
**[pull_request](#pull_request)**
actions (depending on how you've configured this action).

You can use `#` followed by text to add a comment at the end of a line.
Note that some automatic pruning may not properly handle this.

:warning: This was previously called `whitelist` -- that name is *deprecated*.
Support for the deprecated name may be removed in a future release.
Until then, warnings will be reported in the action run log.
At a future date, comments may report this as well.

##### only

This file contains Perl regular expressions.
Generally, one regular expression per line.
They are merged using an `OR` (`|`).

Files not matching these patterns will be skipped.

See the wiki for [only examples](
https://github.com/check-spelling/check-spelling/wiki/Configuration-Examples:-only)

Lines that start with `#` will be ignored.

##### patterns

This file contains Perl regular expressions.
Generally, one regular expression per line.
Lines that begin with `#` will be skipped.
They are merged using an `OR` (`|`).

Tokens within files that match these expressions will be skipped.

See the wiki for [pattern examples](
https://github.com/check-spelling/check-spelling/wiki/Configuration-Examples:-patterns)

##### reject

This allows you to remove words from the dictionary
without having to replace the core dictionary.

The order of operations is:

> `(dictionary + allows) - reject`

### Optional Configuration Variables

| Variable | Description |
| ------------- | ------------- |
| VERBOSE | `1` if you want to be reminded of how many words are in your expect list for each run. |
| [bucket](#bucket) | file/url for which the tool has read access to a couple of files. |
| [project](#project) | a folder within `bucket`. This allows you to share common items across projects. |
| [timeframe](#timeframe) | number of minutes (default 60) to consider when a **[schedule](#schedule)** workflow checks for updated PRs. |

##### bucket

* unset - especially initially...
* `./path` - a local directory
* `ssh://git@*`, `git@*` - git urls (if the url isn't for github, you'll need to have set up credentials)
* `https://` (or `http://`) - curl compatible
* `gs://` - gsutil url

##### project

* unset - especially initially
* branch - for git urls
* `./` - if you don't need an extra nesting layer
* directory - especially for sharing a general bucket across multiple projects

##### timeframe

Used by the **[schedule](#schedule)** action. Any open pull requests from another repository
will be checked, and if the commit is within that timeframe, it will be processed.

## GitHub Action Events

Supported GitHub actions:

* [push](#push)
* [pull_request_target](#pull_request_target)
* [pull_request](#pull_request) :warning:
* [schedule](#schedule)

### push

This is the easiest event to explain. When the owner of a repository pushes a
commit (or tag, unless you exclude that -- which you may want to do), the
spell checker can run and comment on the commit.

Comments on commits will appear when those commits are offered as part of a
pull request to another repository.

:warning: Forks can disable actions, and thus it's possible for this workflow
not to have been run by your contributors.

Example workflow snippet:

```workflow
on:
  push:
    branches:
      - "**"
    tags-ignore:
      - "**"
jobs:
  build:
    name: Spell checking
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2.0.0
      with:
        fetch-depth: 5
    - uses: check-spelling/check-spelling@master
```

### pull\_request\_target

```workflow
on:
  push:
  pull_request_target:
jobs:
  build:
    name: Spell checking
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2.0.0
      with:
        ref: ${{ github.event.pull_request.head.sha }}
        fetch-depth: 5
    - uses: check-spelling/check-spelling@master
```

If there are unrecognized tokens,
this should trigger [annotations](#Comment_as_seen_in_a_commit)
for around 10 unrecognized tokens and a [comment](#Comment_as_seen_in_a_PR).

Items beyond that can be viewed in the [action log](#GitHub_Action_Run_log).

The comment includes a command that can be used to update the repository
to accept the tokens (if they are not misspelled).

This feature is new with 0.0.17.

### pull\_request

:warning: While you can use `pull_request`, its use is discouraged.
Instead, the recommended event is
[pull_request_target](#pull_request_target).

### schedule

:information_source: With 0.0.17,
you can migrate to [pull_request_target](#pull_request_target) instead.

This is basically a cron job run by GitHub. It will look through open
PRs and comment if they've been updated since the last run.

See [timeframe](#timeframe) for the configuration window.

Example workflow snippet:

```workflow
on:
  push:
  schedule:
    # * is a special character in YAML so you have to quote this string
    - cron: '15 * * * *'
```

Cons: There will not be a :x: for the PR, so you have to look
for a comment.

## Running locally

Yes you can!

### Running locally with Act

1. [Install Act](https://github.com/nektos/act#installation)
1. `act`

:warning: This may break at times as act may be missing support for newer GitHub Actions features.

## Behavior

* This action will automatically comment on commits (if configured
using [push](#push))
or PRs
(if configured using
[pull_request_target](#pull_request) /
[schedule](#schedule) /
[pull_request](#pull_request))
with its opinion.
* It will try to identify a limited number of lines containing the words it
doesn't recognize.

# License

[MIT](LICENSE.txt)
