# Script that builds a wrc-test resouce DLL file

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
If (${Env:APPVEYOR} -eq "True")
{
	Invoke-Expression -Command "& '${MSBuild}' ${MSBuildOptions} ${VSSolutionFile} /logger:'C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll'";
}
Else
{
	Invoke-Expression -Command "& '${MSBuild}' ${MSBuildOptions} ${VSSolutionFile}"
}

Exit ${ExitSuccess}
