---
title: "Integrating Python's Virtualenv with Fish shell Without Overcomplicated Frameworks"
description: "This blog offers a solution to seamlessly integrate Python's virtualenv with the Fish shell, enhancing its user experience and productivity."
author: "Anton Ohorodnyk"
date: "2023-06-10T13:12:16-07:00"
type: "post"
---
## Introduction

The [Fish shell][fish] is renowned for its user-friendly nature, making it an ideal command-line interface for macOS, Linux, and more. The shell stands out with its unique features, including auto-completion, syntax highlighting, and tabbed completion. Additionally, its learning curve is gentle enough for beginners to grasp quickly.

Despite these attractive attributes, many developers I've come across don't prefer [Fish shell][fish], primarily due to integration gaps with tools like [Python][python]'s [virtualenv][virtualenv]. So, in this article, I'm offering a simple solution for automatic [virtualenv][virtualenv] activation for [Fish shell][fish], steering clear of resource-intensive frameworks like [oh-my-fish][omf] that often slow down the shell.

## Understanding Python's Virtualenv

[Python][python]'s [virtualenv][virtualenv] is a tool that creates isolated [Python][python] environments, making it an invaluable resource for managing project dependencies and testing [Python][python]'s new versions without affecting the system's main installation.

> It is perplexing and perhaps not ideal to have [Python][python]'s dependencies installed globally instead of project-specific folders. This issue necessitates workarounds such as [virtualenv][virtualenv].

## The Objective

Before diving into the solution, let's clearly define our goal.

### Task

We aim to automate the activation of [virtualenv][virtualenv] when we navigate into the project folder or any of its sub-folders. Additionally, we want to deactivate [virtualenv][virtualenv] when exiting the project's scope.

A bottom-up search for the [virtualenv][virtualenv] folder is crucial as multiple [virtualenv][virtualenv]s can reside within the project folder, and we need to use the nearest one.

The ultimate goal is to devise a minimalist solution to minimize performance hindrances and ensure maximum compatibility with any Fish environment.

### Solution: An Adapted Plugin

I adapted the code from [timothybrown/fish-autovenv](https://github.com/timothybrown/fish-autovenv), originally created by [Timothy Brown](https://github.com/timothybrown), and published the modified version on GitHub.

The existing solution had a few shortcomings:

* It was incompatible with newer versions of Fish, and my goal was to retain simplicity.
* The plugin for created for [oh-my-fish][omf], which is a resource-intensive framework that slows down the shell.
* The plugin could only detect virtual environments in the current directory, not in specified sub-directories. For instance, I store my virtual environments in a .venv sub-directory.
* The plugin didn't apply the virtual environment when opening a terminal in a directory containing a custom virtual environment.
* It searched for [virtualenv][virtualenv]s top-down (`/home`, `/home/user`, `/home/user/projects`, `/home/user/projects/pytest`), whereas a bottom-up approach would have been more efficient and user-friendly.

As a minimalist plugin manager for Fish, I recommend [fisher][fisher]. I've created a plugin that can be installed via [fisher][fisher] and integrated into any Fish environment. If there are any reasons why you don't want to use Fisher, you can just copy-paste `conf.d/autoenv.fish` file to your `~/.config/fish/conf.d` directory.

The project can be found here: [aohorodnyk/fish-autovenv][autovenv].

### Installation

To install [aohorodnyk/fish-autovenv][autovenv], by using [fisher][fisher]:

```fish
fisher install aohorodnyk/fish-autovenv
```

The plugin offers several configurable settings for a tailored user experience:

* `set -U autovenv_enable yes|no` - to enable or disable the plugin (enabled by default).
* `set -U autovenv_announce yes|no` - to enable or disable announcements when [virtualenv][virtualenv] is activated or deactivated (enabled by default).
* `set -U autovenv_dir '.venv'` - to specify the name of the directory where [virtualenv][virtualenv] is located (default is `.venv`).

## Conclusion

Don't be apprehensive about using the [Fish shell][fish]. It's a versatile, fast, and intuitive shell, making it a worthy alternative to bash and zsh.

Contributing to open-source is an excellent way to learn, help others, and contribute to making the technological world better and simpler for everyone.

[omf]: https://github.com/oh-my-fish/oh-my-fish
[fish]: https://fishshell.com/
[fisher]: https://github.com/jorgebucaran/fisher
[autovenv]: https://github.com/aohorodnyk/fish-autovenv
[python]: https://www.python.org/
[virtualenv]: https://virtualenv.pypa.io/
