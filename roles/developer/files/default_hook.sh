#!/bin/sh

if [ -x `pwd`/.git/hooks/$(basename $0) ];
then
    exec `pwd`/.git/hooks/$(basename $0)
fi