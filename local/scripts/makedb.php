<?php
// Args: 0 => makedb.php, 1 => "$JOOMLA_DB_HOST", 2 => "$JOOMLA_DB_USER", 3 => "$JOOMLA_DB_PASSWORD", 4 => "$JOOMLA_DB_NAME", 5 => "$JOOMLA_DB_TYPE"
$stderr = fopen('php://stderr', 'w');
fwrite($stderr, "\nEnsuring Joomla database is present\n");

if (strpos($argv[1], ':') !== false)
{
	list($host, $port) = explode(':', $argv[1], 2);
}
else
{
	$host = $argv[1];
	$port = null;
}

$user = $argv[2];
$password = $argv[3];
$db = $argv[4];
$dbType = strtolower($argv[5]);

$port = $port ? (int)$port : 3306;
$maxTries = 10;

// set original default behaviour for PHP 8.1 and higher
// see https://www.php.net/manual/en/mysqli-driver.report-mode.php
mysqli_report(MYSQLI_REPORT_OFF);
do {
	$mysql = new mysqli($host, $user, $password, '', $port);

	if ($mysql->connect_error)
	{
		fwrite($stderr, "\nMySQL Connection Error: ({$mysql->connect_errno}) {$mysql->connect_error}\n");
		--$maxTries;

		if ($maxTries <= 0)
		{
			exit(1);
		}

		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($db) . '`'))
{
	fwrite($stderr, "\nMySQL 'CREATE DATABASE' Error: " . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

fwrite($stderr, "\nMySQL Database Created\n");

$mysql->close();