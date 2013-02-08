<?php

/**
 * @author 
 * @copyright 2013
 */
 $site = nl2br(htmlentities(file_get_contents("http://www.youtube.com/results?search_query=" . urlencode((isset($_GET['q']) ? $_GET['q'] : null)))));
$pos = strpos($site, "/watch?v=");
//$redirect = "http://www.youtube.com" . substr ( $site , $pos, 20 ) . "&hd=1";
$id=substr ( $site , $pos+9, 11 );


//header( 'Location: ' . $redirect ) ;
?>

<object type="application/x-shockwave-flash" width="150" height="25" data="https://www.youtube-nocookie.com/v/<?php echo $id; ?>?version=2&autoplay=1&loop=1&hd=1&theme=dark"><param name="movie" value="https://www.youtube-nocookie.com/v/<?php echo $id; ?>?version=2&autoplay=1&hd=1&theme=dark" /><param name="wmode" value="transparent" /></object>