<?php

/**
 * @author 
 * @copyright 2013
 */

?>

search: <?php echo (isset($_GET['q']) ? $_GET['q'] : null); ?>.<br>


<?php
 //   echo nl2br(htmlentities(file_get_contents("http://tinysong.com/b/ke$ha+c'mon?format=json&key=fd795fccf23e00e5f37d54a8afe21025")));
    //$myjson = nl2br(htmlentities(file_get_contents("http://tinysong.com/b/ke$ha+c'mon?format=json&key=fd795fccf23e00e5f37d54a8afe21025")));
    $myjson = nl2br(htmlentities(file_get_contents("http://tinysong.com/b/" . urlencode((isset($_GET['q']) ? $_GET['q'] : null)) . "?format=json&key=fd795fccf23e00e5f37d54a8afe21025")));
$letters = array(',');
$fruit   = array(':');

$json2  = str_replace($letters, $fruit, $myjson);
$arr = explode(":",$json2);
echo $arr[4];
?>







<!DOCTYPE html><html><head>
<title>Magicsong</title>
<style type="text/css">
html,body
{
	text-align: center;
	background-color: #333;
	color: #DDD;
	padding: 0;
}
h1 { font-family: sans-serif; }
h2 { font-style: italic; font-weight: normal; }
a:link {
	text-decoration: none;
	font-weight: bold;
	color: #D33;
}
a:visited { color: #933; }
a:hover { color: #D66; }
input[type='text']
{
	width: 200px;
}
input
{
	background-color: #292929;
	color: #DDD;
	border: 1px solid #999;
}


</style>
</head>
<body>

<object width="250" height="40" data="http://grooveshark.com/songWidget.swf">
	<param name="flashvars" value="hostname=cowbell.grooveshark.com&amp;songID=<?php echo $arr[4]; ?>&amp;style=metal&amp;p=1&amp;useSecure=no&amp;secureService=no&amp;isSecure=false&amp;allowInsecureDomain=true&amp;baseURLSecure=false&amp;ignoreInitFail=true&amp;volume=0.25">
	<param name="allowScriptAccess" value="Always">
</object>

<br>
<br>
<form action="" method="GET">
	<input type="text" name="q" value="">
	<input type="submit" value="New Song">
</form>
<p>
<!--	<a href="http://tinysong.com/19tZZ">Play in Grooveshark</a> -->
<!--	:: -->
	<a href="#" onclick="javascript:window.location.href = window.location.href;">Reload</a>
</p>



</body></html>