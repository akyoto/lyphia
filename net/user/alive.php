<?php
	include("../../../wp-blog-header.php");
	$id = $wpdb->escape($_GET["id"]);
	$wpdb->query("UPDATE lyphia_users SET last_alive = NOW() WHERE id = $id");
?>
