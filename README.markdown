<html>
<body>
<h2 style="margin: 0.0px 0.0px 10.0px 0.0px; font: 24.0px Helvetica"><b>Depencies</b></h2>
<p>The I Bike CPH project makes use of several sub-libraries, listed below. For additional dependencies consult the documentation of relevant libraries.</p>
<p>See the individual license files in the sub-libraries for more information on each.</p>
<ul>
  <li><a href="https://developers.facebook.com/resources/facebook-ios-sdk-current.pkg">Facebook SDK</a></li>
  <li><a href="http://dl.google.com/dl/gaformobileapps/GoogleAnalyticsiOS.zip">Google Analytics SDK</a></li>
</ul>


<h2 style="margin: 0.0px 0.0px 10.0px 0.0px; font: 24.0px Helvetica"><b>Build</b></h2>
<p><b>Facebook SDK:</b>  install Facebook SDK and then copy or link ~/Documents/FacebookSDK/ into main project. The best place to create a link would be Libs folder using:<br/> <b>ln -s path_to_FacebookSDK_folder FacebookSDK</b></p>
<p><b>Google Analytics:</b>  copy or link Library/* into main project. The best place to create a link would be Libs folder using:<br/> <b>ln -s path_to_Google_Analytics_folder GoogleAnalytics</b></p>


<h2 style="margin: 0.0px 0.0px 10.0px 0.0px; font: 24.0px Helvetica"><b>Run</b></h2>

<p>In order to run the app you'll need to create a <b>smroute_settings_private.plist</b> in ibikecph folder. A file called <b>EXAMPLE_smroute_settings_private.plist</b> has been placed in the same folder to get you started. Just copy it to <b>smroute_settings_private.plist</b> and change the info. <b>

<br/>DO NOT CHANGE THE EXAMPLE FILE AND COMMIT IT. YOUR LOGIN INFO WILL END UP IN THE REPOSITORY FOR ALL TO SEE.</b>

<br/><br/>Also, you'll need to edit <b>smroute_settings.plist</b> in ibikecph folder. You should not commit changes to this file.<b>

</p>


</body>
</html>
