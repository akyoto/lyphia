<?php
	include("../../../wp-blog-header.php");
	$players = $wpdb->get_results("SELECT name, points, kills, wins, loses FROM lyphia_users WHERE id = " . $wpdb->escape($_GET["id"]) ." LIMIT 1");
	
	// Return player info
	if(count($players) == 1) {
		$player = $players[0];
		echo $player->name . "\n";
		echo $player->points . "\n";
		echo $player->kills . "\n";
		echo $player->wins . "\n";
		echo $player->loses . "\n";
	} else {
		echo "-1\n";
	}
?>
