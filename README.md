# PsWebServer
Description: A Simple PowerShell Execution Server
Backstory: I once needed to provide a simple way to for the orchestration team to access our SCCM system.  My idea is to set up a web server (HTTP) to listen for requests, so that the orchestration engine can simply call a URL to execute a particular PowerShell script on or agains the SCCM site server.  After searching the internet for a decent amount of time, I wasn't able to find anything that does just that.  So, I decided to piece something together from a few different sources, to build a Web Server that can take a URL and execute a script.

This engine can process normal HTML files, as well as a special file format with embedded PowerShell code, developed specific for this purpose, I call it, PSP - PowerShell Server-side Pages. When rending a PSP file, the embedded PowerShell code is processed first on the server side, then the results will be compiled with the HTML code into the response back to the web browser client.

Example:
```
<html>
  <body>
    <table border=1>
      <tr>
        <td>Server Hostname: </td><td><%$env:Computername%></td>
      </tr>
      <tr>
      	<td>IP Address: </td><td><%([system.net.dns]::GetHostAddresses($enc:computername).ipaddresstostring)[0]%></td>
      </tr>
      <tr>
        <td>C:\ Content: </d></td>
	<td>
          <% 
	    "Current Folder: $(pwd) <br><br>"
            dir c:\ | % {"$_ <br>"}
          %>
	</td>
      </tr>
    </table>
  </body>
</html>
```
Results:

![Results](https://raw.githubusercontent.com/ssrtist/PsWebServer/master/example2results.jpg?_sm_au_=isVtZNqs6MZMWnG5)
     
