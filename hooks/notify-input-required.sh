#!/bin/bash

# Claude Code Notification for User Input Required

powershell.exe -NoProfile -Command "
\$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
\$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

\$APP_ID = 'Claude Code'
\$template = @'
<toast>
    <visual>
        <binding template='ToastText02'>
            <text id='1'>Claude Code</text>
            <text id='2'>User input required</text>
        </binding>
    </visual>
    <audio src='ms-winsoundevent:Notification.SMS' />
</toast>
'@

\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
" 2>/dev/null

exit 0
