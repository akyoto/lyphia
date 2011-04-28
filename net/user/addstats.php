<?php
	include("../../../wp-blog-header.php");
	$id = $wpdb->escape($_GET["id"]);
	$points = $wpdb->escape($_GET["points"]);
	$kills = $wpdb->escape($_GET["kills"]);
	$wins = $wpdb->escape($_GET["wins"]);
	$loses = $wpdb->escape($_GET["loses"]);
	$wpdb->query("UPDATE lyphia_users SET points = points + $points, kills = kills + $kills, wins = wins + $wins, loses = loses + $loses WHERE id = $id");
?>
