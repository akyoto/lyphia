<?php
	include("../../../wordpress/wp-blog-header.php");
	$id = $wpdb->escape($_GET["id"]);
	$roomName = $wpdb->escape($_GET["roomname"]);
	$wpdb->query("UPDATE lyphia_users SET room_name = `$roomName` WHERE id = $id");
?>