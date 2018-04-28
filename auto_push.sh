#!/bin/sh

git add ./
date=`date +%Y%m%d`
git commit -m $date
git push origin master