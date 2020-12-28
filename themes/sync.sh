#!/usr/bin/env bash

THEME="hugo-future-imperfect-slim"
rm -rf ./${THEME}
git clone git@github.com:pacollins/hugo-future-imperfect-slim.git
rm -rf ${THEME}/.git
git add -- ./${THEME}/
git commit -m"Update ${THEME} theme" -- ./${THEME}
