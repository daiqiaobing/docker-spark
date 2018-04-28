#!/bin/sh

git add ./
date=`date -d next-day +%Y%m%d`
git commit -m $date
git push origin master