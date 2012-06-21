##### SET SOME GLOBAL VARIABLES #####
$rootDrive = "C:"
$javaHome = "C:\java\jdk1.6"
$svnworkHome = $rootDrive + "\svnwork"
$toolsHome = $rootDrive + "\tools"
$mavenHome = $toolsHome + "\maven"
$userHome = $env:USERPROFILE
$time = Get-Date -Format r

##### IMPORT SVN URLS #####
. "ignoredFiles\svnUrls.ps1"

##### GET LATEST BRANCH VERSION #####
$branchVersion = svn ls $branchUrl | Sort-Object -Descending | Select-Object -First 1 -Skip 1 | %{$_ -replace '/','' }

##### CREATE LOG FILE #####
$logfile = $svnworkHome + "\logfile.txt"

function logEvent ($logString) {
	$time = Get-Date -Format T
	Write-Output "$logString $time"
	Write-Output "$logString $time" >> $logfile
}

##### FUNCTIONS FOR SVNWORK INSTALL #####

##### TOOLS SETUP #####
function installTools {
    configureSubversion
    installJunction
    installMaven
    installAnt
    installXmlBeans
}

##### CREATE DIRECTORIES AND PULL FILES FROM SVN #####
function setupDirectories {
	$dirList = 'prr','defaultui','customers','techservices','svnscripts'
	foreach ($dir in $dirList)
	{
		if ((Test-Path $svnworkHome\$dir) -eq $True) {
			logEvent "$dir already exists"
		}
		else
		{
			New-Item -Type directory -Path $svnworkHome\$dir
			logEvent "Created $svnworkHome\$dir"
		}
	}
	
	#getSvnScripts
	getFiles -remoteUrl $svnScriptsUrl -localFolder svnscripts -workingClean working
	#getTechServices
	getFiles -remoteUrl $techservicesUrl -localFolder techservices -workingClean working
	#getPrrTrunk
	getFiles -remoteUrl $prrTrunkUrl -localFolder prr -workingClean working
	#getDefaultUiTrunk
	getFiles -remoteUrl $defaultUiTrunkUrl -localFolder defaultui -workingClean clean
	#getCustomersTrunk
	getFiles -remoteUrl $customersTrunkUrl -localFolder customers -workingClean clean
	#getPrrBranch $branchVersion
	getFiles -remoteUrl $prrBranchUrl -localFolder prr -currentBranchVersion $branchVersion -workingClean working
	createSymLink -linkName branch -linkUrl $svnworkHome\prr\$branchVersion
	#getDefaultUiBranch $branchVersion
	getFiles -remoteUrl $defaultUiBranchUrl -localFolder defaultui -currentBranchVersion $branchVersion -workingClean clean
	createSymLink -linkName branch -linkUrl $svnworkHome\defaultui\$branchVersion
}

function getFiles ($remoteUrl, $localFolder, $currentBranchVersion, $workingClean) 
{
	logEvent ("Installing {0}" -f $localFolder)
	if ($currentBranchVersion)
	{
		svn co ($remoteUrl+$branchVersion) $svnworkHome\$localFolder\$branchVersion\$workingClean
	}
	else
	{
		svn co $remoteUrl $svnworkHome\$localFolder\trunk\$workingClean
	}
	
	if ($workingClean -eq 'clean')
	{
        if ($currentBranchVersion)
        {
			logEvent "Installing $localFolder\$branchVersion clean to working"
			copy-item $svnworkHome\$localFolder\$branchVersion\clean -destination $svnworkHome\$localFolder\$branchVersion\working -recurse
        }
        else 
        {
			logEvent "Copying $localFolder clean to working"
            copy-item $svnworkHome\$localFolder\trunk\clean -destination $svnworkHome\$localFolder\trunk\working -recurse
        }

	}
}

function createSymLink ($linkName, $linkUrl) {
	Junction.exe $linkName $linkUrl
}

function configureSubversion {
    "Enable storing of plaintext SVN password" >> $logfile
    "store-plaintext-passwords = yes" >> $userHome\.subversion\servers
    "Configuring subversion" >> $logfile
    svn cat https://dev.bazaarvoice.com/svn/bvc/ops/trunk/scm/client/config > $userHome\.subversion\config
}

function installJunction {
    New-Item -Type directory -Path $toolsHome\junction
    cd $toolsHome\junction
    $filename = "junction-current.zip" 
    copy-item \Users\joshua.melvin\Downloads\$filename (Get-Location).Path
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace((Get-Location).Path + "\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Remove-Item $filename
}

function installMaven {
    cd $toolsHome
    $filename = "maven-current.zip"
    copy-item \Users\joshua.melvin\Downloads\$filename (Get-Location).Path
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace((Get-Location).Path + "\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Remove-Item $filename
    Get-ChildItem -Filter "*maven*" | Rename-Item -NewName "maven"

    New-Item -Type directory -Path ($userHome+"\.m2")
    Copy-Item ($svnworkHome+"\techservices\trunk\working\tools\bin\maven-install\ts-maven-settings.xml") ($userHome+"\.m2\settings.xml")
    New-Item -Type file -Path ($userHome+"\.mavenrc")
    echo MAVEN_OPTS='"-Xms256m -Xmx2g -XX:MaxPermSize=256m -server"' > ($userHome+"\.mavenrc")

}

function installAnt {
    cd $toolsHome
    $filename = "ant-current.zip"
    copy-item \Users\joshua.melvin\Downloads\$filename (Get-Location).Path
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace((Get-Location).Path + "\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Remove-Item $filename
    Get-ChildItem -Filter "*ant*" | Rename-Item -NewName "ant"
}

function installXmlBeans {
    cd $toolsHome
    $filename = "xmlbeans-current.zip"
    copy-item \Users\joshua.melvin\Downloads\$filename (Get-Location).Path
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace((Get-Location).Path + "\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Remove-Item $filename
    Get-ChildItem -Filter "*xmlbeans*" | Rename-Item -NewName "xmlbeans"
}

function addEnvSetup {
	Add-Content -Path $profile -Value ('$env:JAVA_HOME' + " = $javaHome")
	Add-Content -Path $profile -Value ('$env:MAVEN_HOME' + " = $mavenHome")
	Add-Content -Path $profile -Value ('$env:TOOLS_HOME' + " = $toolsHome")
	Add-Content -Path $profile -Value ('$env:path' + " += ;$toolsHome\junction;$toolsHome\maven\bin;$toolsHome\ant\bin;$toolsHome\xmlbeans;$javaHome;$javaHome\bin;")
}


##### BEGIN INSTALLATION #####
Write-Output "Windows Bazaarvoice Dev Environment Setup Script\n" > $logfile
logEvent "Started install at"

#installTools
#setupDirectories

addEnvSetup
logEvent "Install completed"
 
##### END INSTALLATION #####