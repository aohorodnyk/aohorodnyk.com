---
title: "Fish with auth virtualenv for python"
description: "How to use fish with auth virtualenv for python?"
author: "Anton Ohorodnyk"
date: "2023-06-10T13:12:16-07:00"
type: "post"
---
## Introduction

Fish is a smart and user-friendly command line shell for macOS, Linux, and the rest of the family. It's a fully-featured shell that's easy to use and supports powerful features like auto-completion, syntax highlighting, and tabbed completion. Fish is also a great choice for beginners because it's easy to learn and use.

However, despite these features, Fish is not the favored shell among the developers I encounter. So, since this shell was not spread enough, there are some integration gaps with other tools. One of them is virtualenv for python.

When I tried to find the solution to do automatic virtualenv activation for fish, but without using [oh-my-fish][omf] and related overcomplecated frameworks that uses a lot of resources and makes shell slow, I found only one solution that works for me. But even found solution was updated 4 years ago and it was not working for me, at least without [oh-my-fish][omf]

## Python's virtualenv

Python's virtualenv is a tool that allows you to create isolated Python environments. It's a great way to keep your projects separate and avoid dependency conflicts. It's also useful for testing new versions of Python without affecting your system installation.

> I cannot (and maybe don't want) to understand why python's dependencies installed globally, but not in the project folder. It's a big problem that we must solve by all these hacks like virtualenv.

## Solution

Before we will try to solve the problem, let's try to understand what we want to achieve.

### Task

We want to activate virtualenv automatically when we enter the project folder or any below folders under the project folter. And we want to deactivate virtualenv when we leave the project folder's space.

It's important to search a virtualenv's folder bottom-up, because we can have a lot of virtualenvs in the project folder and we want to use the closest one.

We want to use as minimalistic solution as possible to avoid any performance issues and make it as compatible as possible with any fish environment.

### Plugin

To solve the issue I forked code from [fish-autovenv](https://github.com/timothybrown/fish-autovenv) built by [Timothy Brown](https://github.com/timothybrown) and shared it on github.

I've found a couple of issues with the existing solution:

* The plugin did not work with the new version of fish, and I wanted to keep it as simple as possible.
* The plugin looked for virtual environments in the current directory, but not in the specified sub-directory. For example I store virtual env in a sub-directory called .venv.
* It does not apply virtual environment when run a terminal in a directory with a custom virtual environment.
* It searches virtualenv from bottom to top: `/home`, `/home/user`, `/home/user/projects`, `/home/user/projects/pytest`. I believe that bottom-up solution makes more sense and it's more convenient to use.

I use [fisher][fisher] as a minimalistic plugin manager for fish. So, I created a plugin that can be installed by [fisher][fisher] and used in any fish environment.

Project is located here: [aohorodnyk/fish-autovenv][autovenv].

### Installation

To install the plugin, you need to use [fisher][fisher]:

```fish
fisher install aohorodnyk/fish-autovenv
```

The plugin itself has a couple of configurations you can use to customize it:

* `set -U autovenv_enable yes|no` - enable or disable the plugin. By default it's enabled.
* `set -U autovenv_announce yes|no` - enable or disable the announcement when virtualenv is activated or deactivated. By default it's enabled.
* `set -U autovenv_dir '.venv'` - set the name of the directory where virtualenv is located. By default it's `.venv`.

## Conclusion

Don't afraid to use fish shell. It's a great shell that can be used for any purpose. It's fast, it's smart and it's easy to use. It's a great alternative to bash and zsh.

And contribute to the open source. It's a great way to learn new things and to help other people. It helps to make the world better and simpler for everyone.

[omf]: https://github.com/oh-my-fish/oh-my-fish
[fish]: https://fishshell.com/
[fisher]: https://github.com/jorgebucaran/fisher
[autovenv]: https://github.com/aohorodnyk/fish-autovenv
