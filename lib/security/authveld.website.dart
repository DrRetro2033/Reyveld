part of 'authveld.dart';

/// Builds an authorization page that will be displayed to the user.
///
/// The page will ask the user if they want to allow the application to access
/// Reyveld with the given permissions. If the user clicks the "Allow" button,
/// the application will be authorized and the user will be redirected to the
/// Reyveld application. If the user clicks the "Deny" button, the application
/// will be denied authorization and the user will be redirected to the
/// Reyveld application.
///
/// The page is built using a HTML template and the [formattedPermissions] set
/// is used to generate the list of permissions that the application is
/// requesting.
String buildAuthPage(
    String applicationName, String ticketId, List<SPolicy> permissions) {
  SPolicySafetyLevel safetyLevel = SPolicySafetyLevel.safe;
  for (final policy in permissions) {
    final safety = policy.safetyLevel;
    if (safety.index > safetyLevel.index) safetyLevel = safety;
  }
  String iconName = "cancel";
  String color = "check-bad";
  String tooltip = "This application is unsafe.";
  switch (safetyLevel) {
    case SPolicySafetyLevel.safe:
      iconName = "check_circle";
      color = "check-good";
      tooltip = "This application should be safe.";
      break;
    case SPolicySafetyLevel.warn:
      iconName = "error";
      color = "check-warning";
      tooltip = "This application may be unsafe.";
      break;
    case SPolicySafetyLevel.unsafe:
      iconName = "cancel";
      color = "check-bad";
      tooltip = "This application is unsafe.";
      break;
  }
  return """<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AuthVeld</title>
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=$iconName" />
    <style>
        body {
            margin: 0;
            background: #181a1b;
            font-family: sans-serif;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }

        .disclaimer {
            align-items: center;
            justify-content: center;
            color: grey;
            font-size: 11px;
            text-shadow: 2px 2px 2px #000000;
        }

        h1 {
            padding-top: 6px;
            margin: 0;
            transition: all 0.3s ease;
        }

        h2 {
            padding-top: 10px;
            padding-bottom: 10px;
            margin: 0;
            transition: all 0.3s ease;
        }

        .bubble {
            background: #181a1b;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            display: flex;
            flex-direction: column;
            padding: 1em;
        }

        .auth-dialog.expanded .bubble {

            height: 100%;
        }

        .auth-dialog {
            text-align: center;
            position: fixed;
            left: 50%;
            transform: translateX(-50%);
            width: 400px;
            padding: 1em;
            transition: all 0.3s ease;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            z-index: 1000;
        }

        .auth-dialog.expanded {
            text-align: left;
            top: 5%;
            left: 5%;
            right: 5%;
            bottom: 5%;
            transform: none;
            width: auto;
            max-height: none;
        }

        .auth-dialog.done {
            text-align: center;
            position: fixed;
        }

        .permission-list {
            text-align: left;
        }

        .summary {
            cursor: pointer;
            display: block;
            transition: background 0.3s ease;
            padding: 10px;
            border-radius: 12px 12px 0 0;
        }

        .auth-dialog.expanded .summary {
            display: none;
        }

        .auth-dialog.done .summary {
            display: none;
        }

        .summary:hover {
            background: #3a3f42;
        }

        .details {
            display: none;
            overflow-y: auto;
            flex: 1;
            border-top: 1px solid #ddd;
        }

        .auth-dialog.expanded .details {
            display: block;
        }

        .auth-dialog.done .details {
            display: none;
        }

        .frame {
            width: 100%;
            height: 100%;
        }

        .actions {
            gap: 16px;
            display: flex;
            justify-content: flex-end;
            position: absolute;
            right: 0;
            margin: 0;
            padding: 0;
            height: 100%;
            width: 100%;
        }

        .auth-dialog.expanded .actions {
            justify-content: flex-end;
        }

        .auth-dialog.done .actions {
            display: none;
        }

        .done-dialogue {
            text-align: center;
            position: fixed;
            left: 50%;
            transform: translateX(-50%);
            width: 400px;
            padding: 1em;
            background: #181a1b;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            z-index: 1000;
            display: none;
        }

        button {
            max-width: 100px;
            flex: 1;
            margin: 0;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
        }

        ul {
            margin: 0;
        }

        .allow {
            background-color: #007bff;
            color: white;
        }

        .allow:hover {
            background-color: #0056b3;
        }

        .deny {
            background-color: #2a2d2f;
            color: white;
        }

        .deny:hover {
            background-color: #3a3f42;
        }

        .back {
            background-color: #2a2d2f;
            color: white;
            display: none;
            left: 0;
            position: absolute;
            height: 100%;
            width: 100%;
        }

        .back:hover {
            background-color: #3a3f42;
        }

        .auth-dialog.expanded .back {
            display: initial
        }


        .check {
            text-align: left;
            padding: 8px;
            font-size: 1.2rem;
            display: flex;
            align-items: center;
        }

        #check-good {
            color: green;
        }

        #check-warning {
            color: yellow;
        }

        #check-bad {
            color: red;
        }

        .bg-image {
            z-index: 1;
            background-image: url("https://4kwallpapers.com/images/wallpapers/monster-hunter-3840x2160-19126.jpeg");
            background-color: #f5f6f7;
            background-position: center;
            background-repeat: no-repeat;
            background-size: cover;
            filter: blur(8px);
            -webkit-filter: blur(8px);
            height: 100%;
            width: 100%;
        }

        .md-48 {
            margin: 0;
            font-size: 30px !important;
            cursor: pointer;
        }

        .tooltip {
            position: relative;
            display: inline-block;
        }

        .tooltip .tooltiptext {
            visibility: hidden;
            width: 120px;
            background-color: #555;
            color: white;
            text-align: center;
            border-radius: 6px;
            padding: 5px 0;
            position: absolute;
            z-index: 1;
            top: -2px;
            right: 105%;
            margin-left: -60px;
            opacity: 0;
            transition: opacity 0.3s;
            font-size: 16px;
        }



        .tooltip:hover .tooltiptext {
            visibility: visible;
            opacity: 1;
        }

        .bottom-row {
            position: relative;
            height: 40px;
            border-top: 1px solid #ddd;
            margin-bottom: 10px;
            padding-top: 10px;
        }
    </style>
</head>

<body>
    <div class="bg-image"></div>
    <div class="done-dialogue" id="doneDialogue">
        <h1 id="finish-message-header">Done</h1>
    </div>
    <div class="auth-dialog" id="authDialog">
        <div class="bubble">
            <h1>AuthVeld</h1>
            <h2>$applicationName wants Access</h2>
            <div class="summary" id="summary" onclick="expandDialog()">
                <strong>$applicationName</strong> is requesting access to Reyveld.
                <p><strong>Requested permissions:</strong></p>
                <ul class="permission-list">
                    ${permissions.map((p) => '<li>${p.description}</li>').join('\n')}
                </ul>
            </div>

            <div class="details">
                <iframe class="frame" id="details" frameborder="0"></iframe>
            </div>
            <div class="bottom-row">
                <div class="actions">

                    <div class="check tooltip" id="$color"
                        style="font-variation-settings: 'FILL' 1, 'wght' 700, 'GRAD' 0, 'opsz'24;">
                        <span class="material-symbols-outlined md-48">$iconName</span>
                        <span class="tooltiptext" M>$tooltip</span>
                    </div>
                    <button class="deny" onclick="handleDeny()">Deny</button>
                    <button class="allow" onclick="handleAllow()">Allow</button>

                </div>
                <button class="back" onclick="shinkDialog()">Back</button>
            </div>
        </div>
        <p class="disclaimer">Safety checks are based on the permissions the application is asking for, and not the
            trustworthiness of the app itself. Make sure you trust the app & developer before continuing.</p>
    </div>

    <script>
        setSource();
        let hasFinished = false;
        window.addEventListener('beforeunload', (event) => {
            if (hasFinished) return;
            // Most browsers no longer allow custom messages in the confirmation dialog.
            // Returning a string or setting returnValue might trigger a default browser prompt.
            event.preventDefault(); // Prevents the default action (page unload)
            event.returnValue = ''; // Setting returnValue for older browser compatibility
        });
        function expandDialog() {
            document.getElementById('authDialog').classList.add('expanded');
        }

        function shinkDialog() {
            document.getElementById('authDialog').classList.remove('expanded');
        }

        function handleAllow() {
            fetch(`http://127.0.0.1:7274/authorize\${window.location.search}`, {
                method: "POST",
            });
            document.getElementById("finish-message-header").innerText = "Access Granted.";
            document.getElementById('authDialog').remove();
            document.getElementById('doneDialogue').style.display = "block";
            hasFinished = true;
        }

        function handleDeny() {
            fetch(`http://127.0.0.1:7274/deauthorize\${window.location.search}`, {
                method: "POST",
            });
            document.getElementById("finish-message-header").innerText = "Access Denied.";
            document.getElementById('authDialog').remove();
            document.getElementById('doneDialogue').style.display = "block";
            hasFinished = true;
        }

        function setSource() {
            document.getElementById('details').src = `/permissions/details\${window.location.search}`
        }

    </script>

</body>

</html>
""";
}

String get expiredTicketPage => """<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AuthVeld</title>
    <link rel="stylesheet"
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=check_circle" />
    <style>
        body {
            margin: 0;
            background: #181a1b;
            font-family: sans-serif;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }

        h1 {
            padding-top: 6px;
            margin: 0;
            transition: all 0.3s ease;
        }

        h2 {
            padding-top: 10px;
            padding-bottom: 10px;
            margin: 0;
            transition: all 0.3s ease;
        }

        .done-dialogue {
            text-align: center;
            position: fixed;
            left: 50%;
            transform: translateX(-50%);
            width: 400px;
            padding: 1em;
            background: #181a1b;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            transition: all 0.3s ease;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            z-index: 1000;
        }

        .bg-image {
            z-index: 1;
            background-image: url("https://4kwallpapers.com/images/wallpapers/monster-hunter-3840x2160-19126.jpeg");
            background-color: #f5f6f7;
            background-position: center;
            background-repeat: no-repeat;
            background-size: cover;
            filter: blur(8px);
            -webkit-filter: blur(8px);
            height: 100%;
            width: 100%;
        }
    </style>
</head>

<body>
    <div class="bg-image"></div>
    <div class="done-dialogue" id="doneDialogue">
        <h1 id="finish-message-header">Ticket Expired.</h1>
        <p>The AuthVeld ticket has already expired.</p>
    </div>
</body>

</html>""";
