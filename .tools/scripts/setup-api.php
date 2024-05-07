<?php
/**
 * @package    Joomla E2E Test Suite
 * 
 * @author     Charvi Mehra <https://github.com/charvimehradu>
 *             Martina Scholz <https://github.com/LadySolveig>
 * 
 * @copyright  (C) 2024 Open Source Matters, Inc.
 * @license    GNU General Public License version 2 or later; see LICENSE.txt
 */

$tokenSeed = $argv[1];
$siteSecret = $argv[2];
$userId = $argv[3];
$site = $argv[4];
$algorithm = 'sha256';

$rawToken  = base64_decode($tokenSeed);
$tokenHash = hash_hmac($algorithm, $rawToken, $siteSecret);
$bearer   = base64_encode("$algorithm:$userId:$tokenHash");

$label = "API_" . strtoupper(preg_replace('/^' . preg_quote('Joomla-', '/') . '/', '', $site));

if (file_put_contents('/usr/src/Projects/.tools/.secret', $label . '=' . $bearer . PHP_EOL , FILE_APPEND | LOCK_EX)) {
    echo ' > API Token for ' . $site . ' has been set.' . PHP_EOL . PHP_EOL;
} else {
    echo ' > API Token for ' . $site . ' could not be set.' . PHP_EOL . PHP_EOL;
};

?>