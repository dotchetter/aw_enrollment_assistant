# aw_enrollment_assistant
## Notice: This project is depricated and is not being maintained. Use at your own discretion.

Batch-file tool to automate agent enrollment for Windows to Airwatch

Language in prompts: English

Simple batch-program that streamlines the BOYD or STAGING enrollment flow with Windows and AirWatch.
Uses 'AirWatchAgent.msi' by VMWare to pass on commandline switches.

The tool takes following conditions in to consideration:

* Current enrollment state (Throws error if machine is enrolled) 
* Presence of 'AirWatchAgent.msi'
* Post-enrollment attempt state (error checks whether machine enrolls to the tenant or not)

How to use

1. Declare variables line 45 - 57. These strings will be passed to "AirWatchAgent.msi". 
   Read available switches here: 
   https://docs.vmware.com/en/VMware-AirWatch/9.1/vmware-airwatch-guides-91/GUID-AW91-Enroll_SilentCommands.html

2. Save the source file main.cmd and run it with elevated permissions. 
   The script will detect if you need to download the agent file or not.			
