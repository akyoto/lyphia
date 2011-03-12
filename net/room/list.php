<?php
	include("../../../wordpress/wp-blog-header.php");
	$players = $wpdb->get_results("SELECT ip, room_name FROM lyphia_users WHERE room_name IS NOT NULL ORDER BY room_date DESC");
	
	// TODO: After last_login + 10 minutes, delete the room
	
	echo count($players) . "\n";
	
	// Return room list
	foreach($players as $player) {
		echo $player->ip . "\n";
		echo stripslashes($player->room_name) . "\n";
	}
?>