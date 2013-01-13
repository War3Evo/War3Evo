<?php

/**
 * @author 
 * @copyright 2013
 */
 $site = nl2br(htmlentities(file_get_contents("http://www.youtube.com/results?search_query=" . urlencode((isset($_GET['q']) ? $_GET['q'] : null)))));
$pos = strpos($site, "/watch?v=");
$redirect = "http://www.youtube.com" . substr ( $site , $pos, 20 ) . "&hd=1";




header( 'Location: ' . $redirect ) ;
?>
