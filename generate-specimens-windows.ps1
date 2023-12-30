# Script to generate Windows resource test files

Param (
	[string]$Configuration = ${Env:Configuration},
	[string]$Platform = ${Env:Platform},
	[string]$PlatformToolset = "",
	[string]$VisualStudioVersion = ""
)

$ExitSuccess = 0
$ExitFailure = 1

If (-Not ${VisualStudioVersion})
{
	$VisualStudioVersion = "2017"

	Write-Host "Visual Studio version not set defauting to: ${VisualStudioVersion}" -foreground Red
}
If ((${VisualStudioVersion} -ne "2017") -And (${VisualStudioVersion} -ne "2019"))
{
	Write-Host "Unsupported Visual Studio version: ${VisualStudioVersion}" -foreground Red

	Exit ${ExitFailure}
}
$MSBuild = ""

If (${VisualStudioVersion} -eq "2017")
{
	$Results = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force

	If ($Results.Count -gt 0)
	{
		$MSBuild = $Results[0].FullName
	}
}
ElseIf (${VisualStudioVersion} -eq "2019")
{
	$Results = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force

	If ($Results.Count -gt 0)
	{
		$MSBuild = $Results[0].FullName
	}
}
If (-Not ${MSBuild})
{
	Write-Host "Unable to determine path to msbuild.exe" -foreground Red

	Exit ${ExitFailure}
}
ElseIf (-Not (Test-Path ${MSBuild}))
{
	Write-Host "Missing msbuild.exe: ${MSBuild}" -foreground Red

	Exit ${ExitFailure}
}

$VSSolutionFile = "wrc-test.sln"

If (-Not (Test-Path "${VSSolutionFile}"))
{
	Write-Host "Missing Visual Studio ${VisualStudioVersion} solution file: ${VSSolutionFile}" -foreground Red

	Exit ${ExitFailure}
}
If (-Not ${Configuration})
{
	$Configuration = "Release"

	Write-Host "Configuration not set defauting to: ${Configuration}"
}
If (-Not ${Platform})
{
	$Platform = "x86"

	Write-Host "Platform not set defauting to: ${Platform}"
}
$PlatformToolset = ""

If (-Not ${PlatformToolset})
{
	If (${VisualStudioVersion} -eq "2017")
	{
		$PlatformToolset = "v141"
	}
	ElseIf (${VisualStudioVersion} -eq "2019")
	{
		$PlatformToolset = "v142"
	}
	Write-Host "PlatformToolset not set defauting to: ${PlatformToolset}"
}
$MSBuildOptions = "/verbosity:quiet /target:Build /property:Configuration=${Configuration},Platform=${Platform}"

If (${PlatformToolset})
{
	$MSBuildOptions = "${MSBuildOptions} /property:PlatformToolset=${PlatformToolset}"
}

$Mc = ""

$Results = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\*\bin\*\x86\mc.exe" -Recurse -ErrorAction SilentlyContinue -Force

If ($Results.Count -gt 0)
{
	$Mc = $Results[0].FullName
}

If (${Mc})
{
	Invoke-Expression "& '${Mc}' -A wrc-test\wrc-test.mc -h wrc-test -r wrc-test"

	Copy-Item -Destination "rc-files\messagetable.rc" -Force -Path "wrc-test\wrc-test.rc"

	Invoke-Expression "& '${Mc}' -um wrc-test\wrc-test.eventman -r wrc-test"

	Copy-Item -Destination "rc-files\wevt_template.rc" -Force -Path "wrc-test\wrc-test.rc"
}

New-Item -Force -ItemType "directory" -Name "specimens" -Path "."

$RCFiles = Get-ChildItem -Include *.rc -Path "rc-files\*"

Foreach (${File} in ${RCFiles})
{
	$Filename = ${File}.Basename

	Copy-Item -Destination "wrc-test\wrc-test.rc" -Force -Path "rc-files\${Filename}.rc"

	Remove-Item -ErrorAction Ignore -Force -Path "Release" -Recurse
	Remove-Item -ErrorAction Ignore -Force -Path "wrc-test\Release" -Recurse

	Invoke-Expression -Command "& '${MSBuild}' ${MSBuildOptions} ${VSSolutionFile}"

	Copy-Item -Destination "specimens\wrc-test-${Filename}.dll" -Force -Path "Release\wrc-test.dll"
}

$Muirct = ""

$Results = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\*\bin\*\x86\muirct.exe" -Recurse -ErrorAction SilentlyContinue -Force

If ($Results.Count -gt 0)
{
	$Muirct = $Results[0].FullName
}

If (${Muirct})
{
	Invoke-Expression "& '${Muirct}' -q rcconfig-files/stringtable.rcconfig specimens\wrc-test-stringtable.dll specimens\wrc-test-stringtable.dll.ln specimens\wrc-test-stringtable.dll.mui"
}

Exit ${ExitSuccess}
