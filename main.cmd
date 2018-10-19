	:: Enrolls unit to VMWare Workspace ONE UEM, AirWatch as a staging user.
	:: Edit desired enrollment scenario using the staging user from the AirWatch console. 
	:: No maintenance is provided for this file and no warranty is issued.
	:: Encoded Windows 1252 for ASCII Characters. To recompile source code, re-open with encoding Windows 1252.
	:: File version 1.9
	:: Syntax: Batch, Language: Swedish
	:: May the force be with you
	
	:: -- HOW TO USE:

	:: 1. Declare variables line 32 - 43. These strings will be passed to "AirWatchAgent.msi". 
	::    - Read available switches here: https://docs.vmware.com/en/VMware-AirWatch/9.1/vmware-airwatch-guides-91/GUID-AW91-Enroll_SilentCommands.html
	:: 2. Save this source file and run it with elevated permissions. The script will detect if you need to download the agent file or not.		
	
	@echo off
	setlocal enabledelayedexpansion	
	setlocal enableextensions

	set logfilepth=%Appdata%\EnrollmentAssistant\log.log
	set curdir=%~dp0
	set enrolledpromptstr=Datorn verkar redan vara ansluten till AirWatch. Dubbelkolla genom att titta under 'Inställningar - Konton - Åtkomst till arbete eller skola.' Om inte, prova att starta om datorn och försök sedan igen.
	set enrollstr="%windir%\system32\msiexec.exe /i %curdir%\AirWatchAgent.msi ENROLL=Y IMAGE=N SERVER=%server% LGName=%groupID% USERNAME=%username% PASSWORD=%stagingpwd% STAGEUSERNAME=%stageusername% STAGEPASSWORD=%stagingpwd% /quiet"
	set initpromptmsgstr=Detta program kommer att ansluta din enhet till %customernm%'s AirWatch. Om en begränsningsprofil är konfigurerad i AirWatch, kan du inte gå ur AirWatch-hanteringen självmant via datorns Inställningar. Vill du fortsätta? Detta tar ungefär 3-5 minuter.
	set errnotfoundstr=Du måste ha 'AirWatchAgent.msi' i samma mapp som detta program, annars misslyckas det. Vill du ladda ned filen nu? Tryck Ja, och välj att -spara- filen.
	set errstr=Anslutningen till AirWatch nådde timeout och misslyckades. Kontrollera nätverksanslutningen samt att serverinformationen och kontouppgifterna i programmet stämmer. Se logg '%logfilepth%' för detaljer.
	set successstr=Anslutningen lyckades. Datorn är ansluten till '%server%'.

	:: Edit following set of variables to enroll machines to AirWatch. Do not use "" or ''.

		:: enrollment user password:
		set stagingpwd=
		:: enrollment user username in AirWatch (e.g. enrollment@customer.com): 
		set stageusername=
		:: enrollment user email adress in AirWatch:
		set username=
		:: AirWatch device server url (e.g. ds222.awmdm.com):
		set server=
		:: GroupID for OU in AirWatch in which to enroll users, where enrollment user is present. (found in details, under Groups & Settings):
		set groupID=
		:: Customer name will be printed out in GUI forms throughout the program. (e.g. Company AB)
		set customernm=


:func_main
	
	echo [%date% - %time%] -- ============== Starting new session. ============== >> %logfilepth%

	:: verifies .msi installer existence, calls label depending on outcome
	md "%AppData%\EnrollmentAssistant"
	
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
		call :func_initprompt
	
	) else (

		if %errorlevel%==0 (
			echo [%date% - %time%] -- The machine appears to already be enrolled to AirWatch. RegKey 'HKLM\Software\AirWatch\awsecure' is present in registry. Exiting...>> %logfilepth%
			call :obj_enrolledprompt
			)
		)

:obj_enrolledprompt

	:: prints a prompt in case function 'main' determines the computer as already enrolled to AirWatch

	echo wscript.quit MsgBox ("%enrolledpromptstr%", 6, "Datorn verkar redan vara ansluten") > %temp%\enrolledprompt.vbs
	wscript //nologo %temp%\enrolledprompt.vbs
	del %temp%\enrolledprompt.vbs
	
	endlocal
	exit

:func_initprompt

	:: prints a 'Y/N' prompt to proceed in case function 'main' determines the computer as not enrolled.

	echo wscript.quit MsgBox ("%initpromptmsgstr%", 4, "Anslut din dator till %customernm%'s AirWatch") > %temp%\initprompt.vbs
	wscript //nologo %temp%\initprompt.vbs
	set value=%errorlevel%

	if %value%==6 (
		echo [%date% - %time%] -- User acknowledged enrollment, running enrollment string aimed at 'AirWatchAgent.msi'... >> %logfilepth%
		del %temp%\initprompt.vbs
		start /wait %enrollstr%
			
	) else (
		
		echo [%date% - %time%] -- User denied enrollment, exiting and deleting temp files... >> %logfilepth%
		del %temp%\initprompt.vbs
		endlocal
		exit
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
	echo wscript.quit MsgBox ("%errstr%", 6, "Ett fel uppstod") > %temp%\error.vbs
	wscript //nologo %temp%\error.vbs
	
	del %temp%\error.vbs
	del %temp%\initprompt.vbs

	endlocal
	exit

:error_notfound

	:: called in case the 'AirWatchAgent.msi' file is not found in current execution directory
	
	echo [%date% - %time%] -- The 'AirWatchAgent.msi' file was not found in %curdir% nor in user download directory. Prompting for download... >> %logfilepth%
	echo wscript.quit MsgBox ("%errnotfoundstr%", 4, "Filen sakas") > %temp%\errnotfound.vbs
	wscript //nologo %temp%\errnotfound.vbs
	set value=%errorlevel%	

	if %value%==6 (
		echo [%date% - %time%] -- User acknowledged download, browser windows will open and user will option to save the file.  Exiting... >> %logfilepth%
		start https://www.awagent.com/Home/DownloadWinPcAgentApplication
		del %temp%\errnotfound.vbs
		endlocal
		exit
		
	) else (
	
		echo [%date% - %time%] -- User denied download. Exiting...  >> %logfilepth%
		del %temp%\errnotfound.vbs
		endlocal
		exit
	)

:successprompt

	:: prompts user that the enrollment was successful
	
	echo [%date% - %time%] -- Device enrolled successfully and is now connected to %server%. Exiting and deleting temp files. >> %logfilepth%
	echo wscript.quit MsgBox ("%successstr%", 6, "Anslutning lyckades!") > %temp%\success.vbs
	wscript //nologo %temp%\success.vbs
	timeout > nul /t 15
	del %temp%\success.vbs
	endlocal
	exit
