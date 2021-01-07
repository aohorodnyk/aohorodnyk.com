#!/usr/bin/env bash

update_theme() {
  THEME_URL=$1
  THEME=$(echo ${THEME_URL} | grep -oe "[^\/]\+.git$" | sed "s/.git//g")
  echo "Updating ${THEME}..."

  rm -rf ./${THEME}
  git clone $THEME_URL
  rm -rf ${THEME}/.git
  git add -- ./${THEME}/
  git commit -m"Update ${THEME} theme" -- ./${THEME}

  echo "Updated ${THEME}"
}

update_theme "git@github.com:aohorodnyk/hugo-future-imperfect-slim.git"
