#!/usr/bin/env bash

THEME="hugo-future-imperfect-slim"
rm -rf ./${THEME}
git clone git@github.com:aohorodnyk/hugo-future-imperfect-slim.git --branch aohorodnyk
rm -rf ${THEME}/.git
git add -- ./${THEME}/
git commit -m"Update ${THEME} theme" -- ./${THEME}
