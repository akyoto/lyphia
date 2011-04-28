<?php
	include("../../../wp-blog-header.php");
	$myrows = $wpdb->get_results("SELECT id, name FROM lyphia_users WHERE login = '" . $wpdb->escape($_GET["login"]) . "' AND password = '" . $wpdb->escape($_GET["password"]) ."' LIMIT 1");
	
	// IP
	if(!isset($_GET['host']))
		$userIP = $_SERVER['REMOTE_ADDR'];
	else
		$userIP = gethostbyname($_GET['host']);
	
	// Return player id
	if(count($myrows) == 1) {
		$id = $myrows[0]->id;
		echo $id . "\n";
		echo $myrows[0]->name . "\n";
		
		$wpdb->query("UPDATE lyphia_users SET ip = '$userIP', last_login = NOW() WHERE id = '$id'");
	} else {
		echo "-1\n";
		echo "\n";
	}
?>
