
:: Enrolls unit to VMWare Workspace ONE UEM formely known as 'AirWatch' as a staging user.
:: Edit desired enrollment scenario using the staging user from the AirWatch console. 
:: No maintenance is provided for this file and no warranty is issued. Switches are referred to by documentation provided by vmware.
:: File version 1.9.1
:: Syntax: Batch, Lang: English
:: May the force be with you

:: Compile this file with bat2exe converter to make an encrypted executable.

@echo off
setlocal enabledelayedexpansion	
setlocal enableextensions

set logfilepth=%Appdata%\EnrollmentAssistant\log.log
set curdir=%~dp0
set enrolledpromptstr=It appears as though this machine is already enrolled to an MDM. Plese check under account settings.
set enrollstr="%windir%\system32\msiexec.exe /i %curdir%\AirWatchAgent.msi ENROLL=Y IMAGE=N SERVER=%server% LGName=%groupID% USERNAME=%username% PASSWORD=%stagingpwd% STAGEUSERNAME=%stageusername% STAGEPASSWORD=%stagingpwd% /quiet"
set initpromptmsgstr=This machine will enrol to  %customernm%'s AirWatch. If a restriction profile is configured, you won't be able to unenroll manually. It will take approx. 3-5 minutes. Continue? 
set errnotfoundstr=You need 'AirWatchAgent.msi' in the same directory as this file. Press yes to open a browser for download. SELECT SAVE.
set errstr=Enrollment to AirWatch reached timeout and failed. Check your connection and make sure the server credentials are correct. See '%logfilepth%' for details.
set successstr=Enrollment successful. This machine is enrolled to '%server%'.

:: Edit following set of variables to enroll machines to AirWatch. Do not use "" or ''.
:: enrollment user password (reset enrollment user password post-enrollment to prevent unwanted enrollment):
set stagingpwd=
:: enrollment user username in AirWatch (e.g. enrollment@customer.com): 
set stageusername=
:: enrollment user email adress in AirWatch:
set username=
:: AirWatch device server url (e.g. ds000.awmdm.com):
set server=
:: GroupID for OU in AirWatch in which to enroll users, where enrollment user is present. (found in details, under Groups & Settings):
set groupID=
:: Customer name will be printed out in GUI forms throughout the program. (e.g. Company AB)
set customernm=

:main
	
	md "%AppData%\EnrollmentAssistant"
	echo [%date% - %time%] -- ============== Starting new session. ============== >> %logfilepth%
	:: verifies .msi installer existence, calls label depending on outcome
	if exist "%userprofile%\downloads\AirWatchAgent.msi" (
		echo [%date% - %time%] -- 'AirWatchAgent.msi' was found in User 'download' directory. Moving to '%curdir%'... >> %logfilepth%
		move "%userprofile%\downloads\AirWatchAgent.msi" "%curdir%"
	
	) else (
		if exist "%curdir%\AirWatchAgent.msi" (
			echo [%date% - %time%] -- 'AirWatchAgent.msi' was found in '%curdir%'... >> %logfilepth%
	
		) else (
			if not exist "%curdir%\AirWatchAgent.msi" (
			call :error_notfound		
			)
		)
	)

	:: verifies if the machine is already enrolled to AirWatch by reg query
	reg query > nul HKLM\Software\AirWatch /t REG_BINARY /v awsecure
	if not %errorlevel%==0 (
		echo [%date% - %time%] -- 'AirWatchAgent.msi' is present. Reg key 'awsecure' not present- Machine is not enrolled. >> %logfilepth%
		call :initprompt
	
	) else (

		if %errorlevel%==0 (
			echo [%date% - %time%] -- The machine appears to already be enrolled to AirWatch. RegKey 'HKLM\Software\AirWatch\awsecure' is present in registry. Exiting...>> %logfilepth%
			call :enrolledprompt
			)
		)

:enrolledprompt

	:: prints a prompt in case function 'main' determines the computer as already enrolled to AirWatch
	echo wscript.quit MsgBox ("%enrolledpromptstr%", 6, "An error occured") > %temp%\enrolledprompt.vbs
	wscript //nologo %temp%\enrolledprompt.vbs
	del %temp%\enrolledprompt.vbs && call :quitr

:initprompt

	:: prints a 'Y/N' prompt to proceed in case function 'main' determines the computer as not enrolled.
	echo wscript.quit MsgBox ("%initpromptmsgstr%", 4, "Enrollment to %customernm%'s AirWatch") > %temp%\initprompt.vbs
	wscript //nologo %temp%\initprompt.vbs
	set value=%errorlevel%

	if %value%==6 (
		echo [%date% - %time%] -- User acknowledged enrollment, running enrollment string aimed at 'AirWatchAgent.msi'... >> %logfilepth%
		del %temp%\initprompt.vbs
		start /wait %enrollstr%
			
	) else (
		echo [%date% - %time%] -- User denied enrollment, exiting and deleting temp files... >> %logfilepth%
		del %temp%\initprompt.vbs && call :quitr
	)

	timeout > nul /t 120
	reg query > nul HKLM\Software\AirWatch /t REG_BINARY /v awsecure
	if not %errorlevel%==0 (
		call :error
		
	) else (
		call :successprompt
		del %temp%\initprompt.vbs
	)

:error

	:: Called in case of error during the installation using data from regkey query 
	echo [%date% - %time%] -- ERROR: Enrollment failed, the process timed out. Check credentials for enrollment user, Group ID, server adress and reachability and internet connection. >> %logfilepth%
	echo wscript.quit MsgBox ("%errstr%", 6, "An error occured") > %temp%\error.vbs
	wscript //nologo %temp%\error.vbs
	del %temp%\error.vbs
	del %temp%\initprompt.vbs && call :quitr

:error_notfound

	:: called in case the 'AirWatchAgent.msi' file is not found in current execution directory
	echo [%date% - %time%] -- The 'AirWatchAgent.msi' file was not found in %curdir% nor in user download directory. Prompting for download... >> %logfilepth%
	echo wscript.quit MsgBox ("%errnotfoundstr%", 4, "Missing file") > %temp%\errnotfound.vbs
	wscript //nologo %temp%\errnotfound.vbs
	set value=%errorlevel%	

	if %value%==6 (
		echo [%date% - %time%] -- User acknowledged download, browser windows will open and user will option to save the file.  Exiting... >> %logfilepth%
		start https://www.awagent.com/Home/DownloadWinPcAgentApplication
		del %temp%\errnotfound.vbs
		call :quitr
		
	) else (
		echo [%date% - %time%] -- User denied download. Exiting...  >> %logfilepth%
		del %temp%\errnotfound.vbs && call :quitr
	)

:successprompt

	:: prompts user that the enrollment was successful
	echo [%date% - %time%] -- Device enrolled successfully and is now connected to %server%. Exiting and deleting temp files. >> %logfilepth%
	echo wscript.quit MsgBox ("%successstr%", 6, "Enrollment successful!") > %temp%\success.vbs
	wscript //nologo %temp%\success.vbs
	timeout > nul /t 15
	del %temp%\success.vbs

:quitr

	endlocal
	exit