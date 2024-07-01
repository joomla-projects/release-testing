#!/bin/bash
#
# upgrade_sed.sh – Upgrade sed command >= version 4.8
#
# @package    Joomla E2E Test Suite
#
# @copyright  (C) 2023-2024 Open Source Matters, Inc. <http://www.joomla.org>
# @license    GNU General Public License version 2 or later; see LICENSE.txt#!/bin/bash
#
# To prevent errors from inline sed editing, e.g.
# sed: couldn't open temporary file /var/www/html/test/sed7AXoIk: Permission denied
# GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
# See https://lists.gnu.org/archive/html/info-gnu/2020-01/msg00002.html
# 
# Needed in Ubuntu 20.04.6 LTS with using GNU sed 4.7 and may be deleted after php-8.3 container image update.

# Update the package list and install dependencies
apt-get update && apt-get install -y \
    wget \
    build-essential \
    gettext \
    libgettextpo-dev \
    texinfo

# Download sed source code (example with version 4.8)
wget https://ftp.gnu.org/gnu/sed/sed-4.8.tar.gz

# Extract the tarball
tar -xzf sed-4.8.tar.gz

# Change to the sed directory
cd sed-4.8

# Configure, make, and install sed
./configure && make && make install

# Cleanup
cd ..
rm -rf sed-4.8 sed-4.8.tar.gz
apt-get remove -y \
    wget \
    build-essential \
    gettext \
    libgettextpo-dev \
    texinfo
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# Verify the installation
sed --version
