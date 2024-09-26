#!/bin/bash
# @package    Joomla E2E Test Suite
#
# @author     Charvi Mehra <https://github.com/charvimehradu>, Martina Scholz <https://github.com/LadySolveig>
#
# @copyright  (C) 2024 Open Source Matters, Inc. <http://www.joomla.org>
# @license    GNU General Public License version 2 or later; see LICENSE.txt

set e+x

LOCAL_NAME=joomla-cypress-included:13.14.2v2
BUILD_PATH=${BUILD:-.}

echo "Building $LOCAL_NAME"
echo "Build path: $BUILD_PATH"

docker image build \
    --build-arg USER_ID=$(id -u ${USER}) \
    --build-arg GROUP_ID=$(id -g ${USER}) \
    -t $LOCAL_NAME $BUILD_PATH
    # --progress=plain --no-cache \ # --> debug build process
