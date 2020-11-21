###Hi this script is dealing with vm creation in vcenter, you will also need 2 Esxi and a datastore. Please take care of the CSV file path to change if necessary###
import-Module VMware.VimAutomation.Core
$User="Administrator@vsphere.local"
$EncPWD2=Get-Credential -Message "please enter your vcenter Password" -UserName $User
$EncPWD2.Password | ConvertFrom-secureString | Out-file C:\Users\Public\password2.txt
$SecuredPWD2=Get-Content C:\Users\Public\password2.txt | ConvertTo-SecureString
$Credential=New-Object System.Management.Automation.PSCredential -ArgumentList $User,$SecuredPWD2

###Import the VMs features###
$CSVFile='C:\Users\Public\VMs.csv'
try {
	$ImportCSVFile=import-Csv -Path $CSVFile -delimiter ';'
}
catch {
	$ErrorImport="An error occured, could not be able to import the csv file"
	$ErrorImport
}
###Connection to the Vcenter###
try {
	Connect-VIServer -Server 172.180.0.200 -Credential $Credential ###Be sure to change the Vcenter IP address with your own
}
catch {
$ErrorConnection="An error occured, could not be able to connect to the server VCenter"
$ErrorConnection
}
###Import the features and creation of ours VMs###
$Errorcount=0	###Error count for VM creation
$VMError=@()	###List of the VM failed
$Successcount=0	###Success count for VM creation
$VMCreate=@()	###List of the VM successfuly created
$Cancelcount=0  ###Error count for VM creation
$VMCancel=@()   ###List of the VM cancel by the technician
for($i=0;$i -lt $ImportCSVFile.length;$i++){
	###Features import
	$vmhostname=$importCSVFile.nom[$i]
	$ESXI=$importCSVFile.ESXI[$i]
	$Storage=$importCSVFile.Storage[$i]
	$ISO=$importCSVFile.ISO[$i]
	$Description=$importCSVFile.Description[$i]
	$Memory=$importCSVFile.Memory[$i]
	$CPU=$importCSVFile.CPU[$i]
	$Disk=$importCSVFile.Disk[$i]
	$Provisionning=$importCSVFile.Provisionning[$i]
	$Network=$importCSVFile.Network[$i]
	###Features checking
	Write-Output("Vm hostname : "+$vmhostname)
	Write-Output("ESXI IP : "+$ESXI)
	Write-Output("Storage name : "+$Storage)
	Write-Output("Choosen ISO : "+$ISO)
	Write-Output("The Vm Description : "+$Description)
	Write-Output("Memory in MB : "+$Memory)
	Write-Output("CPU number : "+$CPU)
	Write-Output("Disk capacity in MB : "+$DISK)
	Write-Output("Disk Storage Format : "+$Provisionning)
	Write-Output("Network name : "+$Network)
	$Question=Read-Host ("Please confirm the features by 'yes' or 'no' for the creation of "+$vmhostname)
	if ($Question -eq "yes")
	{
		###Creation of each VM
		if ($importCSVFile.ISO[$i] -eq "debian")
		{New-VM -Name $vmhostname -VMHost $ESXI -Datastore $Storage -Description $Description -NumCpu $CPU -MemoryMB $Memory -DiskMB $Disk -DiskStorageFormat $Provisionning -NetworkName $Network -CD -Floppy -GuestID debian5_64Guest}
		elseif ($importCSVFile.ISO[$i] -eq "ubuntu")
		{New-VM -Name $vmhostname -VMHost $ESXI -Datastore $Storage -Description $Description -NumCpu $CPU -MemoryMB $Memory -DiskMB $Disk -DiskStorageFormat $Provisionning -NetworkName $Network -CD -Floppy -GuestID ubuntu64Guest}
		else {Write-Output("ISO unknown please add it to the database")}
		Start-VM $vmhostname
		Write-Output("Here are the Vm create and it configuration set :")
		try {
		Get-VM -Name $vmhostname -ErrorAction Stop
		$VMCreate+=$vmhostname
		$VMCreate[$Successcount]
		$Successcount++}
		catch {
		$VMError+=$vmhostname
		"An error occured, could not be able to create the VM : "+$VMError[$Errorcount]
		$Errorcount++}
	}
	else {Write-output("Technician has canceled the creation of "+$vmhostname)
	$VMCancel+=$vmhostname
	$VMCancel[$Cancelcount]
	$Cancelcount++}
}
###VMs Briefing###
Write-Output("Here are all the VMs created, total: "+$VMCreate.length)
foreach($Success in $VMCreate){
	$Success
}
Write-Output("Here are all the VMs failed, total: "+$VMError.length)
foreach($Fail in $VMError){
	$Fail
}
Write-Output("Here are all the VMs Canceled, total: "+$VMCancel.length)
foreach($Cancel in $VMCancel){
	$Cancel
}
###Creation of our Variables for the mail reporting###
$Sender1="yourmail@mail.com" ###Be sure to change the email address with your own 
$technician="yourmail@mail.com" ###Be sure to change the email address with your own
$Requester="yourmail@mail.com" ###Be sure to change the email address with your own
$Supervisor="yourmail@mail.com" ###Be sure to change the email address with your own

###Encryption of the password for our mail login###
$EncPWD=Get-Credential -Message "please enter your mail password" -UserName $Sender1
$EncPWD.Password | ConvertFrom-secureString | Out-file C:\Users\Public\password.txt
$SecuredPWD=Get-Content C:\Users\Public\password.txt | ConvertTo-SecureString
$Credential=New-Object System.Management.Automation.PSCredential -ArgumentList $Sender1,$SecuredPWD

###Send report by mail in html form###

##Technician##
#Error VM Creation#
foreach($Fail in $VMError){
Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Error Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FF0000'>An error occured, could not be able to create this VM: $Fail</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}
#Error CSV Import#
if($null -eq $ErrorImport)
{Write-Output("No Import Error")}
else{Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Error Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FF0000'>$ErrorImport</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}
#Error Vcenter Connection#
if($null -eq $Errorconnection)
{Write-Output("No Connection Error")}
else{Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Error Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FF0000'>$Errorconnection</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}
##VM Canceled#
foreach($Cancel in $VMCancel){
Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Canceled Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FFA500'>You have canceled the creation of $vmhostname</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}

##Requester##
#Error Part#
foreach($Fail in $VMError){
Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Error Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FF0000'>An error occured, could not be able to create this VM: $Fail</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}
#Success Part#
foreach($Success in $VMCreate){
Send-MailMessage -from $Sender1 -to $Requester -Subject "Vm Creation Reporting" -Body "Dear,<br>Please notice the reporting of the VM generated by the VMs's script : <font color='00FF00'>$Success</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}	
#Cancel Part#
foreach($Cancel in $VMCancel){
Send-MailMessage -from $Sender1 -to $technician -Subject "Vm Canceled Reporting" -Body "Dear,<br>Please notice the error generated by the VMs's script; <font color='FFA500'>Technician have canceled the creation of $vmhostname</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential}
	
##Supervisor##
$TotalVM=$ImportCSVFile.length
$TotalFailed=$VMError.length
$TotalCreated=$VMCreate.length
$TotalCanceled=$VMCancel.length
Send-MailMessage -from $Sender1 -to $Supervisor -Subject "Vms Reporting" -Body "Dear,<br>Please notice the reporting of the VMs generated by our script: <br><font color='00FF00'>Total VM Created:$TotalCreated/$TotalVM</font><br><font color='FF0000'>Total VM failed:$TotalFailed/$TotalVM</font><br><font color='FFA500'>Total VM Canceled:$TotalCanceled/$TotalVM</font><br>Best Regard,<br>LE Jeremy" -BodyAsHTML -SmtpServer smtp.gmail.com -port 587 -UseSsl -Credential $Credential

###Disconnection to the Vcenter###
Disconnect-VIServer -force:$True