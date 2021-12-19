﻿ <#
.SYNOPSIS
   Manage windows shortcut (.LNK) artifatcs.

   Author: @r00t-3xp10it
   Tested Under: Windows 10 (19043) x64 bits
   Required Dependencies: none
   Optional Dependencies: lnk_parser_cmd.exe {auto-download}
   PS cmdlet Dev version: v2.3.11

.DESCRIPTION
   Auxiliary module of cleantracks cmdlet to manage link (.LNK) files from sellected directory recursive.
   This cmdlet allow users to search for .LNK files \ display .LNK metadata \ Delete .LNK files recursive.
   
.NOTES
   This cmdlet stores the current Date\Time values to be compared againts .lnk files found timestamp,
   and delete them if the current date match the .lnk file CreationTime. By default it scans %Recent%
   directory recursive unless user inputs another directory using -Directory <'absoluct-path'> argument.

   If invoked -Action 'query' argument then cmdlet will only search (not deleting any artifacts found).
   If invoked -Forensic 'True' argument then cmdlet parses all .LNK artifacts metadata onscreen (console).
   If invoked -TimeStamp 'Year' then it searches for .LNK files with the sellected 'Year' TimeStamp attrib.

   WARNING: Depending of the -Directory <'path'> sellection, this function migth broken explorer shortcuts if
   invoked -TimeStamp based on <'Year'> only. Example: If invoked -Directory "$Env:USERPROFILE" -TimeStamp "2021"
   the cmdlet will delete all shortcuts files recursive of %USERPROFILE% because -Directory function works recursive.

.Parameter Action
   Accepts arguments: Clean, Query (default: query)
   
.Parameter TimeStamp
   Accepts arguments: Today, Year (default: today)

.Parameter Forensic
   Accepts arguments: True, False (default: false)

.Parameter PSBanner
   Accepts arguments: True, False (default: true)
   
.Parameter Directory
   Directory to scan recursive (default: $Env:APPDATA\Microsoft\Windows\Recent)
   
.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -Action query
   Search recursive for .LNK files of default Directory

.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -Action clean
   Delete recursive all .LNK files of default Directory
   
.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -Action clean -Directory "$Env:WINDIR\WinSxS"
   Delete recursive all .LNK files of -Directory <'path'> with 'today' timestamp.
   
.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -action query -Directory "$Env:USERPROFILE" -TimeStamp "1999"
   Search recursive for .LNK files of -Directory <'path'> with '1999' year timestamp.
   
.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -action clean -Directory "$Env:USERPROFILE" -TimeStamp Year
   Delete recursive all .LNK files of -Directory <'path'> with current 'Year' timestamp.

.EXAMPLE
   PS C:\> .\Lnk-Sweeper.ps1 -action query -Directory "$Env:WINDIR\WinSxS" -TimeStamp "17/12/2021" -Forensic true
   Search recursive for .LNK files of -Directory <'path'> with 'sellected' timestamp and parse the .LNK metadata.

.OUTPUTS
   [-] Cleaning: windows shortcut (.LNK) artifacts.
                 ------------------------------------------------------------------
                 Directory: C:\Users\pedro\AppData\Roaming\Microsoft\Windows\Recent
                 TimeStamp: 17/12/2021
                 Forensic : false
                 ------------------------------------------------------------------
       deleted : C:\Users\pedro\AppData\Roaming\Microsoft\Windows\Recent\Artifact.lnk
       deleted : C:\Users\pedro\AppData\Roaming\Microsoft\Windows\Recent\SKYNET-20211214-2204.lnk
       deleted : C:\Users\pedro\AppData\Roaming\Microsoft\Windows\Recent\ms-settingswindowsupdate.lnk

.LINK
   https://www.briancarr.org/post/lnk-files
   https://belkasoft.com/forensic-analysis-of-lnk-files
   https://blog.nviso.eu/2017/04/04/tracking-threat-actors-through-lnk-files
 #>


 [CmdletBinding(PositionalBinding=$false)] param(
   [string]$Directory="$Env:APPDATA\Microsoft\Windows\Recent",
   [string]$timeStamp="today",
   [string]$Forensic="false",
   [string]$PSBanner="true",
   [string]$Action="query"
)


$Count = 0
#Current date values
$MyDate = (Date).Day
$MyYear = (Date).Year   
$MyMonth = (Date).Month
$ErrorActionPreference = "SilentlyContinue"
## Disable Powershell Command Logging for current session.
Set-PSReadlineOption –HistorySaveStyle SaveNothing|Out-Null
$host.UI.RawUI.WindowTitle = "@Lnk-Sweeper v2.3.9 {SSA@RedTeam}"

$Banner = @"


 __       __   __   __  __    ______   __     __   ______   ______   ______  ______   ______    
/\ \     /\ "-.\ \ /\ \/ /   /\  ___\ /\ \  _ \ \ /\  ___\ /\  ___\ /\  == \/\  ___\ /\  == \   
\ \ \____\ \ \-.  \\ \  _"-. \ \___  \\ \ \/ ".\ \\ \  __\ \ \  __\ \ \  _-/\ \  __\ \ \  __<   
 \ \_____\\ \_\\"\_\\ \_\ \_\ \/\_____\\ \__/".~\_\\ \_____\\ \_____\\ \_\   \ \_____\\ \_\ \_\ 
  \/_____/ \/_/ \/_/ \/_/\/_/  \/_____/ \/_/   \/_/ \/_____/ \/_____/ \/_/    \/_____/ \/_/ /_/


"@;

If($PSBanner -ieq "True")
{
   Clear-Host
   Write-Host "$Banner" -ForegroundColor Blue
}

If($Action -ieq "clean")
{
   $CharItem = "    deleted :"
   Write-Host "[-] Cleaning: windows shortcut (.LNK) artifacts." -ForegroundColor Blue
}
Else
{
   $CharItem = "    artifact:"
   Write-Host "[-] QueryFor: windows shortcut (.LNK) artifacts." -ForegroundColor Blue
}


If($TimeStamp -ieq "Today" -or $TimeStamp -Match '^(\d+|\d+\d+)/(\d+|\d+\d+)/(\d+\d+\d+\d+)$')
{

   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Search\Delete .LNK files with current 'Day/Month/Year' set in TimeStamp.

   .NOTES
      -TimeStamp parameter accepts string 'today' or date in 'dd/mm/yyyy' format.

   .EXAMPLE
      PS C:\> .\Lnk-Sweeper.ps1 -TimeStamp "today"
      Use 'todays' date to search for .LNK files.

   .EXAMPLE
      PS C:\> .\Lnk-Sweeper.ps1 -TimeStamp "17/12/2021"
      Use 'sellected' date to search for .LNK files.
   #>   

   If($TimeStamp -Match '^(\d+|\d+\d+)/(\d+|\d+\d+)/(\d+\d+\d+\d+)$')
   {
      #parsing timestamp value data!
      $MyDate = $TimeStamp.Split('/')[0]
      $MyYear = $TimeStamp.Split('/')[2]
      $MyMonth = $TimeStamp.Split('/')[1]
   }

   #Display cmdlet settings onscreen.
   Write-Host "              ------------------------------------------------------------------"
   Write-Host "              Directory: $Directory"
   Write-Host "              TimeStamp: ${MyDate}/${MyMonth}/${MyYear}"
   Write-Host "              Forensic : $Forensic"
   Write-Host "              ------------------------------------------------------------------"

   Start-Sleep -Milliseconds 400
   #Search fo all Link artifacts recursive starting on sellected directory!
   Get-ChildItem -Path "$Directory" -Include *.lnk -Recurse | Select-Object * | Where-Object { 
      $_.CreationTime.Day -Match "$MyDate" -and $_.CreationTime.Month -Match "$MyMonth" -and $_.CreationTime.Year -Match "$MyYear" } | ForEach-Object {

         If($Forensic -ieq "True")
         {
            <#
            .SYNOPSIS
               Author: https://code.google.com/archive/p/lnk-parser
               Helper - Parse .LNK file metadata onscreen (terminal)

            .OUTPUTS
               [Distributed Link Tracker Properties]
               Version:                       0
               NetBIOS name:                  desktop-unlaahq
               Droid volume identifier:       fbadb152-faa6-4cd4-a8e7-56df01695110
               Droid file identifier:         a4fef014-7ac4-11eb-b11c-409f383199e6
               Birth droid volume identifier: fbadb152-faa6-4cd4-a8e7-56df01695110
               Birth droid file identifier:   a4fef014-7ac4-11eb-b11c-409f383199e6
               MAC address:                   40:9f:38:31:99:e6
               UUID timestamp:                03/01/2021 (19:30:56.528) [UTC]
               UUID sequence number:          12572
            #>

            If(-not(Test-Path -Path "lnk_parser_cmd.exe" -ErrorAction SilentlyContinue))
            {
               #Download lnk_parser from code.google.com
               iwr -Uri "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/lnk-parser/lnk_parser_cmd.exe" -OutFile "lnk_parser_cmd.exe"|Out-Null
               Unblock-File -Path lnk_parser_cmd.exe #Unblock the binary file downloaded!
            }

            $Count++
            #Run lnk_parser locally
            Write-Host "";.\lnk_parser_cmd.exe -r $_.FullName
            Start-Sleep -Milliseconds 600
         }
         Else
         {
            $Count++
            #Display onscreen the .LNK files found.
            Write-Host "$CharItem"$_.FullName
            Start-Sleep -Milliseconds 600
         }

         If($Action -ieq "clean")
         {
            #Delete the .LNK artifact found.
            Remove-Item -Path $_.FullName -Force
         }
      }
      
}
ElseIf($TimeStamp -ieq "Year" -or $TimeStamp -Match '^(\d+\d+\d+\d+)$')
{
   
   <#
   .SYNOPSIS
      Author: @r00t-3xp10it
      Helper - Search\Delete .LNK files with current 'Year' in TimeStamp.
         
   .NOTES   
      Warning: Depending of the -Directory tree sellection, this function
      migth broken explorer shortcuts if invoked -TimeStamp based on 'Year'

      Example: If invoked -Directory "$Env:USERPROFILE" -TimeStamp "2021"
      Then cmdlet will delete all shortcut .LNK files set by username acc
      because -Directory parameter works recursive on the input directory.

   .NOTES
      -TimeStamp parameter accepts string 'year' or '2021' date formats.

   .EXAMPLE
      PS C:\> .\Lnk-Sweeper.ps1 -TimeStamp "Year"
      Use 'current year' date to search for .LNK files.

   .EXAMPLE
      PS C:\> .\Lnk-Sweeper.ps1 -TimeStamp "2021"
      Use 'sellected year' date to search for .LNK files.
   #>

   If($TimeStamp -Match '^(\d+\d+\d+\d+)$'){$MyYear = "$TimeStamp"}

   #Display cmdlet settings onscreen.
   Write-Host "              ------------------------------------------------------------------"
   Write-Host "              Directory: $Directory"
   Write-Host "              TimeStamp: ${MyYear}"
   Write-Host "              Forensic : $Forensic"
   Write-Host "              ------------------------------------------------------------------"

   Start-Sleep -Milliseconds 400
   #Search fo all Link artifacts recursive starting on sellected directory!
   Get-ChildItem -Path "$Directory" -Include *.lnk -Recurse | Select-Object * | Where-Object {
      $_.CreationTime.Year -Match "$MyYear" } | ForEach-Object {

         If($Forensic -ieq "True")
         {
            <#
            .SYNOPSIS
               Author: https://code.google.com/archive/p/lnk-parser
               Helper - Parse .LNK file metadata onscreen (terminal)

            .OUTPUTS
               [Distributed Link Tracker Properties]
               Version:                       0
               NetBIOS name:                  desktop-unlaahq
               Droid volume identifier:       fbadb152-faa6-4cd4-a8e7-56df01695110
               Droid file identifier:         a4fef014-7ac4-11eb-b11c-409f383199e6
               Birth droid volume identifier: fbadb152-faa6-4cd4-a8e7-56df01695110
               Birth droid file identifier:   a4fef014-7ac4-11eb-b11c-409f383199e6
               MAC address:                   40:9f:38:31:99:e6
               UUID timestamp:                03/01/2021 (19:30:56.528) [UTC]
               UUID sequence number:          12572
            #>

            If(-not(Test-Path -Path "lnk_parser_cmd.exe" -ErrorAction SilentlyContinue))
            {
               #Download lnk_parser from code.google.com
               iwr -Uri "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/lnk-parser/lnk_parser_cmd.exe" -OutFile "lnk_parser_cmd.exe"|Out-Null
               Unblock-File -Path lnk_parser_cmd.exe #Unblock the binary file downloaded!
            }

            $Count++
            #Run lnk_parser locally
            Write-Host "";.\lnk_parser_cmd.exe -r $_.FullName
            Start-Sleep -Milliseconds 600
         }
         Else
         {
            $Count++
            #Display onscreen the .LNK files found.
            Write-Host "$CharItem"$_.FullName
            Start-Sleep -Milliseconds 600
         }

         If($Action -ieq "clean")
         {
            #Delete the .LNK artifacts found.
            Remove-Item -Path $_.FullName -Force
         }
      }

}
Else
{

   #Wrong TimeStamp format
   Write-Host "[x] Error   : Wrong TimeStamp format selection detected .." -ForegroundColor Red -BackgroundColor Black
   Start-Sleep -Seconds 1
   Write-Host "----------------------------------------------------------"
   Write-Host "    Syntax  : .\Lnk-Sweeper.ps1 -TimeStamp `"${MyYear}`""
   Write-Host "    Syntax  : .\Lnk-Sweeper.ps1 -TimeStamp `"${MyDate}/${MyMonth}/${MyYear}`""
   Write-Host "----------------------------------------------------------"
   exit #Exit @Lnk-Sweeper

}


If($Count -eq 0)
{
   #None artifacts found
   Write-Host "[x] Error   : None artifacts found that match the searh criteria .." -ForegroundColor Red -BackgroundColor Black
}


Start-Sleep -Seconds 1
#clean cmdlet artifacts left behind
If(Test-Path -Path "lnk_parser_cmd.exe" -EA SilentlyContinue)
{
   Remove-Item -Path "lnk_parser_cmd.exe" -Force
}
If($PSBanner -ieq "True")
{
   Write-Host ""
}
exit