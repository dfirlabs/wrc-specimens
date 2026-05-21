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
	$VisualStudioVersion = "2022"

	Write-Host "Visual Studio version not set defauting to: ${VisualStudioVersion}" -foreground Red
}
If ((${VisualStudioVersion} -ne "2010") -And (${VisualStudioVersion} -ne "2012") -And (${VisualStudioVersion} -ne "2013") -And (${VisualStudioVersion} -ne "2015") -And (${VisualStudioVersion} -ne "2017") -And (${VisualStudioVersion} -ne "2019") -And (${VisualStudioVersion} -ne "2022"))
{
	Write-Host "Unsupported Visual Studio version: ${VisualStudioVersion}" -foreground Red

	Exit ${ExitFailure}
}
$MSBuild = Get-Command "msbuild.exe" | Select-Object -ExpandProperty Definition

If (-Not ${MSBuild})
{
	If ((${VisualStudioVersion} -eq "2010") -Or (${VisualStudioVersion} -eq "2012"))
	{
		$MSBuild = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
	}
	ElseIf (${VisualStudioVersion} -eq "2013")
	{
		$MSBuild = "C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe"
	}
	ElseIf (${VisualStudioVersion} -eq "2015")
	{
		$MSBuild = "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
	}
	ElseIf (${VisualStudioVersion} -eq "2017")
	{
		$Results = Get-ChildItem -Path "C:\Program Files\Microsoft Visual Studio\${VisualStudioVersion}\*\MSBuild\15.0\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force

		If ($Results.Count -eq 0)
		{
			$Results = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio\${VisualStudioVersion}\*\MSBuild\15.0\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force
		}
		If ($Results.Count -gt 0)
		{
			$MSBuild = $Results[0].FullName
		}
	}
	ElseIf (${VisualStudioVersion} -eq "2019" -Or ${VisualStudioVersion} -eq "2022")
	{
		$Results = Get-ChildItem -Path "C:\Program Files\Microsoft Visual Studio\${VisualStudioVersion}\*\MSBuild\Current\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force

		If ($Results.Count -eq 0)
		{
			$Results = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft Visual Studio\${VisualStudioVersion}\*\MSBuild\Current\Bin\MSBuild.exe" -Recurse -ErrorAction SilentlyContinue -Force
		}
		If ($Results.Count -gt 0)
		{
			$MSBuild = $Results[0].FullName
		}
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
	If (${VisualStudioVersion} -eq "2015")
	{
		$PlatformToolset = "v140"
	}
	ElseIf (${VisualStudioVersion} -eq "2017")
	{
		$PlatformToolset = "v141"
	}
	ElseIf (${VisualStudioVersion} -eq "2019")
	{
		$PlatformToolset = "v142"
	}
	ElseIf (${VisualStudioVersion} -eq "2022")
	{
		$PlatformToolset = "v143"
	}
	Write-Host "PlatformToolset not set defauting to: ${PlatformToolset}"
}
$MSBuildOptions = "/verbosity:quiet /target:Build /property:Configuration=${Configuration},Platform=${Platform}"

If (${PlatformToolset})
{
	# $MSBuildOptions = "${MSBuildOptions} /property:PlatformToolset=${PlatformToolset}"
	$MSBuildOptions = "${MSBuildOptions} /property:WindowsTargetPlatformVersion=10.0"
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

	$DllFile = Get-ChildItem -ErrorAction SilentlyContinue -Filter wrc-test.dll -Path "." -Recurse

	If (-Not ${DllFile})
	{
		Write-Host "Unable to determine path to wrc-test.dll" -foreground Red

		Exit ${ExitFailure}
	}
	Copy-Item -Destination "specimens\wrc-test-${Filename}.dll" -Force -Path ${DllFile}
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
