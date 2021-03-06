# select subscription

$ResourceGroupName = "[SID]-rg"
$location = "[REGION]"
$subscriptionID = "[SUBSCRIPTIONID]"
$SID = "[SID]"

$curDirName= Split-Path $pwd -Leaf  
if($curDirName.ToLower() -ne ("[SID]").ToLower())
{
    Write-Host "Please run the script from the [SID] folder"
    exit 
}

Write-Host "Deployment started: " (Get-Date).ToString("yyyy-MM-dd HH:mm")

$Subscription = Get-AzSubscription -SubscriptionId $SubscriptionId

if (-Not $Subscription) {
    Write-Host -ForegroundColor Red -BackgroundColor White "Sorry, it seems you are not connected to Azure or don't have access to the subscription. Please use Connect-AzAccount to connect."
    exit

}

if(-not (Test-Path ..\..\baseInfrastructure\ppgavset.json -PathType Leaf))
{
    Write-Host -ForegroundColor Red -BackgroundColor White "File ..\..\baseInfrastructure\ppgavset.json does not exit, ensure that your working directory is correct."
    exit
}


Write-Host "Creating the resource group :" $ResourceGroupName
$rg = Get-AzResourceGroup -Name $ResourceGroupName -Location $location -ErrorVariable notPresent -ErrorAction SilentlyContinue
if(!$rg)
{
    New-AzResourceGroup -Name $ResourceGroupName -Location $location -Tag @{SID=$SID}
 }

Write-Host "Creating the proximity placement group and the availability sets"
$res = New-AzResourceGroupDeployment -Name "PPG_AVSet_Creation" -ResourceGroupName $ResourceGroupName -TemplateFile ..\..\baseInfrastructure\ppgavset.json -TemplateParameterFile .\ppgavset.parameters.json -Verbose
if ($res.ProvisioningState -ne "Succeeded") { 
    Write-Error -Message "The deployment failed" 
    exit
}

Write-Host "Provisioning the ASCS Server(s)"
[ASCSServerDeployment]

Write-Host "Provisioning the Application Server(s)"
[AppServerDeployment]

Write-Host "Provisioning the Database Server(s)"
[DBServerDeployment]

Write-Host "Deployment finished: " (Get-Date).ToString("yyyy-MM-dd HH:mm")


