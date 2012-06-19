##### SET SOME GLOBAL VARIABLES #####
param($rootDrive = "C:" )
$javaHome = "C:\java\jdk1.6"
$svnworkHome = $rootDrive + "\svnwork"
$toolsHome = $rootDrive + "\tools"
$mavenHome = $toolsHome + "\maven"
$userHome = $env:USERPROFILE

##### GET LATEST BRANCH VERSION #####
$branchVersion = svn ls $branchUrl | Sort-Object -Descending | Select-Object -First 1 -Skip 1 | %{$_ -replace '/','' }

##### CREATE LOG FILE #####
$logfile = $svnworkHome + "\logfile.txt"

##### FUNCTIONS FOR SVNWORK INSTALL #####
function getFiles ($remoteUrl, $localFolder, $currentBranchVersion, $workingClean) 
{
	Write-Output "Installing $localFolder"; Get-Date >> $logfile
	if ($currentBranchVersion)
	{
		svn co ($remoteUrl+$branchVersion) $svnworkHome\$localFolder\$branchVersion\$workingClean
	}
	else
	{
		svn co $remoteUrl $svnworkHome\$localFolder\trunk\$workingClean
	}
	
	if ($workingClean == 'clean')
	{
        if ($isBranch)
        {
            copy-item $svnworkHome\$localFolder\$branchVersion\clean -destination $svnworkHome\$localFolder\$branchVersion\working -recurse
        }
        else 
        {
            copy-item $svnworkHome\$localFolder\trunk\clean -destination $svnworkHome\$localFolder\trunk\working -recurse
        }

	}
}

function setupSymlinks {

}

##### TOOLS SETUP #####
function installTools {
    configureSubversion
    installJunction
    installMaven
    installAnt
    installXmlBeans
}

function setupDirectories {
	New-Item -Type directory -Path $svnworkHome\prr 
	New-Item -Type directory -Path $svnworkHome\defaultui
	New-Item -Type directory -Path $svnworkHome\customers 
    New-Item -Type directory -Path $svnworkHome\techservices
    New-Item -Type directory -Path $svnworkHome\svnscripts
	
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
	#getDefaultUiBranch $branchVersion
	getFiles -remoteUrl $defaultUiBranchUrl -localFolder defaultui -currentBranchVersion $branchVersion -workingClean clean -isBranch true
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
@"
$env:JAVA_HOME += $javaHome
$env:MAVEN_HOME += $mavenHome
$env:TOOLS_HOME += $toolsHome
$env:path += ";$toolsHome\junction;$toolsHome\maven\bin;$toolsHome\ant\bin;$toolsHome\xmlbeans;$javaHome;$javaHome\bin;"
"@
}

##### BEGIN INSTALLATION #####
Write-Output "Windows Bazaarvoice Dev Environment Setup Script" > $logfile
Write-Output "Started install at: "; Get-Date >> $logfile
setupDirectories
installTools

addEnvSetup
Write-Output "Install completed:"; Get-Date >> $logfile