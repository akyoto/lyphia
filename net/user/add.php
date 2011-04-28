<?php
	include("../../../wp-blog-header.php");
	$login = $wpdb->escape($_GET["login"]);
	$password = $wpdb->escape($_GET["password"]);
	$name = $wpdb->escape($_GET["name"]);
	
	$players = $wpdb->get_results("SELECT * FROM lyphia_users WHERE login = '$login' OR name = '$name'");
	
	if(empty($players)) {
		$wpdb->query("INSERT INTO lyphia_users (login, password, name) VALUES ('$login', '$password', '$name')");
		echo "1\n";
	} else {
		echo "-1\n";
	}
?>
