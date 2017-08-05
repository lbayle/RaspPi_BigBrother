<!-- LoB 16/08/2017 -->

<h2>BigBro</h2>
<br>
<a href="/images">images de la surveillance video</a>
<br>
<a href="/livecam">live-camera</a>
<br>
<a href="http://192.168.42.1:8080">VLC Music player</a> (no login, password=12345ABCDE)
<br>
<br>
<br>
<?php
   #exec("df -h | grep '/dev/root' | awk '{print $4}'");
   $df = round(disk_free_space("/") / 1024 / 1024, 2);
   echo "Espace disque restant: $df Mo";


   echo "<br><br>";
   # check if motion is running
   if (file_exists( "/var/run/motion/motion.pid" )){
      $pid = intval(file_get_contents('/var/run/motion/motion.pid'));
      if (posix_getpgid($pid)) {
         echo "Camera: ON";
     } else {
         echo "Camera: OFF";
     }
   } else {
      echo "Camera: OFF";
   }

   # check if gammu is running
   echo "<br>";
   if (file_exists( "/var/run/gammu-smsd.pid" )){
      $pid = intval(file_get_contents('/var/run/gammu-smsd.pid'));
      if (posix_getpgid($pid)) {
         echo "SMS engine: ON";
     } else {
         echo "SMS engine: OFF";
     }
   } else {
      echo "SMS engine: OFF";
   }

   # check if VLC is running
   echo "<br>";
   exec("pgrep vlc", $pids);
   if(empty($pids)) {
      echo "VLC Muser Player : OFF";
   } else {
      echo "VLC Muser Player : ON";
   }
   echo "<br>";

?>
