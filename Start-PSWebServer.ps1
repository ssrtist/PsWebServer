<#
.Synopsis
	Starts powershell webserver
.Description
	Starts webserver as powershell process.

.Parameter BINDING
	Binding of the webserver

.Example
	Start-Webserver.ps1

	Starts webserver with binding to http://localhost:8080/
.Example
	Start-Webserver.ps1 "http://+:8080/"

	Starts webserver with binding to all IP addresses of the system.
	Administrative rights are necessary.
.Notes
	Author: ssrtist
#>
Param([STRING]$BINDING = 'http://localhost:8080/')

# Starting the powershell webserver
"$(Get-Date -Format s) Starting powershell webserver..."
$LISTENER = New-Object System.Net.HttpListener
$LISTENER.Prefixes.Add($BINDING)
$LISTENER.Start()
$Error.Clear()
$workingDirectory = pwd

try
{
  # Logging to screen and log file
  $LogEntry = "$(Get-Date -Format s) Powershell webserver started."
  $LogEntry
  $logEntry | Out-file "$(($PSCommandPath -split "\.")[0]).log" -append 
  while ($LISTENER.IsListening)
  {
    # analyze incoming request
    $CONTEXT = $LISTENER.GetContext()
    $REQUEST = $CONTEXT.Request
    $RESPONSE = $CONTEXT.Response
	$HTMLRESPONSE = ""
    $RESPONSEWRITTEN = $FALSE

	$logEntry = "$(Get-Date -Format s) $($REQUEST.RemoteEndPoint.Address.ToString()) $($REQUEST.httpMethod) $($REQUEST.Url.PathAndQuery)"
    # log to console
	$logEntry

    # log to file
	$logEntry | Out-file "$(($PSCommandPath -split "\.")[0]).log" -append 

    # parse request
    $RECEIVED = '{0} {1}' -f $REQUEST.httpMethod, $REQUEST.Url.LocalPath
	$localPath = $RECEIVED.replace("$($RECEIVED.split("/")[0])/","")

    # check for known commands
    switch ($RECEIVED)
    {
      "GET /"
      {	# GET default document
		if (Test-Path ".\index.htm") {$localPath = "index.htm"}
		if (Test-Path ".\index.html") {$localPath = "index.html"}
		if (Test-Path ".\index.psp") {$localPath = "index.psp"}
		break
      }

      default
	  {	
		break
      }

    }
	$localExt = ($localPath -split "\.")[1]
    
    # Return to default working directory
    CD $workingDirectory 
	if (($localPath) -and (Test-Path $localPath -PathType Leaf)) {
		switch ($localExt)
		{
			"htm"
			{
				$RESULT = "it's a htm file"
				$HTMLRESPONSE = Get-Content $localPath
			}
			"html"
			{
				$RESULT = "it's a html file"
				$HTMLRESPONSE = Get-Content $localPath
			}
			{$_ -eq "png" -or $_ -eq "jpg" -or $_ -eq "gif"}
			{ # responding to image file requests
				$RESULT = "it's a image file"
				$BUFFER = [System.IO.File]::ReadAllBytes($localPath)
				$RESPONSE.ContentType = "image/$localExt"
				$RESPONSE.OutputStream.Write($BUFFER, 0, $BUFFER.length)
				$RESPONSEWRITTEN = $True
			}
			{$_ -eq "log" -or $_ -eq "txt" -or $_ -eq "xml"}
			{ # responding to text file requests
				$RESULT = "it's a text file"
				$BUFFER = [System.IO.File]::ReadAllBytes($localPath)
				$RESPONSE.ContentType = "text/plain"
				$RESPONSE.OutputStream.Write($BUFFER, 0, $BUFFER.length)
				$RESPONSEWRITTEN = $True
			}
			"psp"
			{
				$RESULT = & {
					$isCode = $false; 
					$myHtml = "";
					$myCmd = ""; 
					(get-content $localPath) | % {
						# detecting inline code block (and execute if found)
						if ($_ -match "\<\%(.+)\%\>") {
							$myCmd = ($_ -split "\<\%(.+)\%\>")[1]; 
							$_ -replace "\<\%(.+)\%\>", "$(Invoke-Expression $myCmd)"; 
							$myCmd = ""; 
						} else {
							# detect beginning of code block
							if ($_ -match "\<\%") {
								$isCode = $true; 
								$myHtml = ($_ -split "\<\%")[0]; 
								$myHtml;
								$myCmd = (($_ -split "\<\%")[1] -replace "#.*") + ";"; 
							}; 
							# detecting end of code block
							if ($_ -match "\%\>") {
								$isCode = $false; 
								$myCmd += (($_ -split "\%\>")[0] -replace "#.*") + ";"; 
								$myHtml = ($_ -split "\%\>")[1]; 
								$myHtml;
							}; 
							# executing code block if complete
							if ($myCmd -and !$isCode) {
								Invoke-Expression $myCmd; $myCmd = ""
							};
						}; 
						# writing out HTML content
						if (!($_ -match "\<\%") -and !($_ -match "\%\>")) {
							if ($isCode) {$myCmd += ($_ -replace "#.*") + ";"; } else {$_; }
						}
					}
				}
				$HTMLRESPONSE = $RESULT
			}
			default
			{
				$RESULT = "file type unknown"
				# $HTMLRESPONSE = "<html><body>Error: File type not supported<br><br></body></html>"
				$HTMLRESPONSE = "<html><body><h1>Error 404: Page not found</h1><br><br></body></html>"
				$RESPONSE.StatusCode = 404
			}
		}
	} else {
	    if (($localPath) -and !(Test-Path $localPath -PathType Leaf)) {
		    # page not found, return error
		    $HTMLRESPONSE = "<html><body><h1>Error 404: Page not found: $(pwd) $localPath</h1><br><br></body></html>"
		    $RESPONSE.StatusCode = 404
	    }
    }

    # only send response if not already done
    if (!$RESPONSEWRITTEN)
    {
    	# return HTML answer to caller
    	$BUFFER = [Text.Encoding]::UTF8.GetBytes($HTMLRESPONSE)
    	$RESPONSE.ContentLength64 = $BUFFER.Length
    	$RESPONSE.OutputStream.Write($BUFFER, 0, $BUFFER.Length)
	}

    # and finish answer to client
    $RESPONSE.Close()

  }
}
finally
{
  # Stop powershell webserver
  $LISTENER.Stop()
  $LISTENER.Close()
  $logEntry = "$(Get-Date -Format s) Powershell webserver stopped."
  $logEntry
  $logEntry | Out-file "$(($PSCommandPath -split "\.")[0]).log" -append 
}
