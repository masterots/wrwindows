##### SET SOME GLOBAL VARIABLES #####
$rootDrive = "C:"
$javaHome = "C:\java\jre"
$svnworkHome = $rootDrive + "\svnwork"
$toolsHome = $rootDrive + "\tools"
$mavenHome = $toolsHome + "\maven"
$userHome = $env:USERPROFILE
$time = Get-Date -Format r

##### IMPORT SVN URLS #####
. "ignoredFiles\svnUrls.ps1"

##### CREATE LOG FILE #####
$logfile = $svnworkHome + "\logfile.txt"

function logEvent ($logString) {
	$time = Get-Date -Format T
	Write-Output "$logString $time"
	Write-Output "$logString $time" >> $logfile
}

##### FUNCTIONS FOR SVNWORK INSTALL #####

##### TOOLS SETUP #####
##### CREATE DIRECTORIES #####
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

function setUpBazaarvoiceHome {
	logEvent "Creating directory structure for \home\bazaarvoice... "
	New-Item -Type directory -Path $rootDrive\home\bazaarvoice 
	
    $dirList = 'config-branch','config-trunk','customers-trunk','promote-logs','reports','logs\diagnostic','logs\request'
    foreach ($dir in $dirList)
    {
        if ((Test-Path $rootDrive\home\bazaarvoice\$dir) -eq $True) {
            logEvent "$dir already exists"
        }
        else
        {
            New-Item -Type directory -Path $rootDrive\home\bazaarvoice\$dir
            logEvent "Created $rootDrive\home\bazaarvoice\$dir"
        }
    }
	
	logEvent "Setting up config-branch... "
	cd $rootDrive\home\bazaarvoice\config-branch 
	New-Item -Type directory -Path 10-localhost 
	Copy-Item $svnworkHome\prr\branch\working\metadata\home\config\30-common\log4j.xml $rootDrive\home\bazaarvoice\config-branch\10-localhost 
	createSymLink 15-overrides-dev-dbscripts $svnworkHome\prr\branch\working\metadata\home\config\15-overrides-dev-dbscripts
	createSymLink 20-overrides-dev $svnworkHome\prr\branch\working\metadata\home\config\20-overrides-dev 
	createSymLink 25-overrides-dev-lab-austin $svnworkHome\prr\branch\working\metadata\home\config\25-overrides-dev-lab-austin 
	createSymLink 30-common $svnworkHome\prr\branch\working\metadata\home\config\30-common 
	
	logEvent "Setting up config-trunk... "
	cd $rootDrive\home\bazaarvoice\config-trunk 
	New-Item -Type directory -Path 10-localhost 
	Copy-Item $svnworkHome\prr\trunk\working\metadata\home\config\30-common\log4j.xml $rootDrive\home\bazaarvoice\config-trunk\10-localhost 
	createSymLink 15-overrides-dev-dbscripts $svnworkHome\prr\trunk\working\metadata\home\config\15-overrides-dev-dbscripts
	createSymLink 20-overrides-dev $svnworkHome\prr\trunk\working\metadata\home\config\20-overrides-dev 
	createSymLink 25-overrides-dev-lab-austin $svnworkHome\prr\trunk\working\metadata\home\config\25-overrides-dev-lab-austin 
	createSymLink 30-common $svnworkHome\prr\trunk\working\metadata\home\config\30-common 

	logEvent "Setting up symbolic links in \home\bazaarvoice for branch use... "
	cd $rootDrive\home\bazaarvoice 
	createSymLink customers $svnworkHome\customers\trunk\working 
	createSymLink config config-branch 
	createSymLink defaultui $svnworkHome\defaultui\branch\working

	logEvent "Copying env.xml, host_overrides.properties, portal_endpoints.properties, and jetty.properties for config-branch... "
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\env.xml $rootDrive\home\bazaarvoice\config-branch\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\host_overrides.properties $rootDrive\home\bazaarvoice\config-branch\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\portal_endpoints.properties $rootDrive\home\bazaarvoice\config-branch\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\jetty.properties $rootDrive\home\bazaarvoice\config-branch\10-localhost
	
	logEvent "Copying env.xml host_overrides.properties, portal_endpoints.properties, and jetty.properties for config-trunk... "
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\env.xml $rootDrive\home\bazaarvoice\config-trunk\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\host_overrides.properties $rootDrive\home\bazaarvoice\config-trunk\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\portal_endpoints.properties $rootDrive\home\bazaarvoice\config-trunk\10-localhost
	copy-item $svnworkHome\techservices\trunk\working\tools\misc\dev-install\jetty.properties $rootDrive\home\bazaarvoice\config-trunk\10-localhost
	
	logEvent "Writing production_secret_key.bin for config-branch... "
	Write-Output "3c774ac04349bbbf861cd59cb7594d09892139227b3dda3411e3f0cdf96da54a" > $rootDrive\home\bazaarvoice\config-branch\production_secret_key.bin
	
	logEvent "Writing production_secret_key.bin for config-trunk... "
	Write-Output "3c774ac04349bbbf861cd59cb7594d09892139227b3dda3411e3f0cdf96da54a" > $rootDrive\home\bazaarvoice\config-trunk\production_secret_key.bin
}

function createSymLink ($linkName, $linkUrl) {
    Junction.exe $linkName $linkUrl
}

function getToolInstallers {
    New-Item -Type directory -Path c:\temp\installers
    cd "\\ausfs01\Client Services\Implementation Design\_Personal Folders\JoshM\"
	Copy-Item *.* "c:\temp\installers"
}

function deleteToolInstallers {
	Remove-Item c:\temp\installers -Recurse
}

function installSubversion {
    logEvent ("Installing subversion")
    C:\temp\installers\Slik-Subversion-1.6.12-x64.msi /passive
    logEvent ("Wait 3 minutes")
    Start-Sleep -s 180
    logEvent ("Completed installing subversion")
}

function configureSubversion {
    "Enable storing of plaintext SVN password" >> $logfile
    New-Item -Type directory -Path $userHome\.subversion
    "store-plaintext-passwords = yes" > $userHome\.subversion\servers
    "Configuring subversion" >> $logfile
    svn cat https://dev.bazaarvoice.com/svn/bvc/ops/trunk/scm/client/config > $userHome\.subversion\config
}

function installJava {
    logEvent ("Installing java")
    C:\temp\installers\jdk-6u30-windows-x64.exe /s INSTALLDIR=$toolsHome\java\jdk
    logEvent ("Wait 3 minutes")
    Start-Sleep -s 180
    logEvent ("Completed installing java")
}

function installJunction {
    logEvent ("Installing junction")
    New-Item -Type directory -Path $toolsHome\junction
    cd $toolsHome\junction
    $filename = "junction-current.zip" 
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace("$rootDrive\temp\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    logEvent ("Completed installing junction")
}

function installMaven {
    logEvent ("Installing maven")
    cd $toolsHome
    $filename = "maven-current.zip"
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace("$rootDrive\temp\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Get-ChildItem -Filter "*maven*" | Rename-Item -NewName "maven"

    New-Item -Type directory -Path ($userHome+"\.m2")
    Copy-Item ($svnworkHome+"\techservices\trunk\working\tools\bin\maven-install\ts-maven-settings.xml") ($userHome+"\.m2\settings.xml")
    New-Item -Type file -Path ($userHome+"\.mavenrc")
    echo MAVEN_OPTS='"-Xms256m -Xmx2g -XX:MaxPermSize=256m -server"' > ($userHome+"\.mavenrc")
    logEvent ("Completed installing maven")
}

function installAnt {
    logEvent ("Installing ant")
    cd $toolsHome
    $filename = "ant-current.zip"
    #copy-item \Users\joshua.melvin\Downloads\$filename (Get-Location).Path
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace("$rootDrive\temp\$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Get-ChildItem -Filter "*ant*" | Rename-Item -NewName "ant"
    logEvent ("Completed installing ant")
}

function installXmlBeans {
    logEvent ("Installing xmlbeans")
    cd $toolsHome
    $filename = "xmlbeans-current.zip"
    $shell_app=new-object -com shell.application  
    $zip_file = $shell_app.namespace("$filename") 
    $destination = $shell_app.namespace((Get-Location).Path) 
    $destination.Copyhere($zip_file.items())
    Get-ChildItem -Filter "*xmlbeans*" | Rename-Item -NewName "xmlbeans"
    logEvent ("Completed installing xmlbeans")
}

function installTools {
    getToolInstallers
    installSubversion
    configureSubversion
    installJava
    installJunction
    installMaven
    installAnt
    installXmlBeans
	deleteToolInstallers
}

function addEnvSetup {
    Add-Content -Path $profile -Value ("`n`$env:JAVA_HOME" + " = `'$javaHome`'")
    Add-Content -Path $profile -Value ("`$env:MAVEN_HOME" + " = `'$mavenHome`'")
    Add-Content -Path $profile -Value ("`$env:TOOLS_HOME" + " = `'$toolsHome`'")
    Add-Content -Path $profile -Value ("`$env:path" + " += `';$toolsHome\junction;$toolsHome\maven\bin;$toolsHome\ant\bin;$toolsHome\xmlbeans;$javaHome;$javaHome\bin;`'")
	. $PROFILE
}


##### BEGIN INSTALLATION #####
Write-Output "Windows Bazaarvoice Dev Environment Setup Script" > $logfile
logEvent "Started install at"

installTools
addEnvSetup
setupDirectories

##### GET LATEST BRANCH VERSION #####
$branchVersion = svn ls $branchUrl | Sort-Object -Descending | Select-Object -First 1 -Skip 1 | %{$_ -replace '/','' }

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

# INSTALL LOCAL LDAP CERTIFICATE
logEvent "Installing local LDAP certificate... "
keytool.exe -importkeystore -alias shareddev -storepass "changeit" -keystore $env:JAVA_HOME\jre\lib\security\cacerts -file $svnworkHome\techservices\trunk\working\tools\misc\dev-install\labCA.pem
logEvent "  Installing local Maven certificate... "
keytool.exe -importkeystore -alias bvrepo -storepass "changeit" -keystore $env:JAVA_HOME\jre\lib\security\cacerts -file $svnworkHome\techservices\trunk\working\tools\misc\dev-install\repo-ssl.cer

logEvent "Install completed"
 
##### END INSTALLATION #####
