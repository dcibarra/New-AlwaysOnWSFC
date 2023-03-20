[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $subscriptionid,
    [Parameter(Mandatory=$true)]
    [string]
    $ServerList,
    [Parameter(Mandatory=$true)]
    [string]
    $witnessaccountname,
    [Parameter(Mandatory=$true)]
    [string]
    $witness_rg,
    [Parameter(Mandatory=$true)]
    [string]
    $clusterip,
    [Parameter(Mandatory=$true)]
    [string]
    $clustername,
    [Parameter(Mandatory=$true)]
    [string]
    $tenantid,
    [Parameter(Mandatory=$true)]
    [string]
    $clientid,
    [Parameter(Mandatory=$true)]
    [string]
    $clientsecret,
    [Parameter(Mandatory=$true)]
    [string]
    # domain user
    $user,
    [Parameter(Mandatory=$true)]
    [string]
    $pass
)
$password = ConvertTo-SecureString $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$password)

Invoke-Command -Credential $cred -ScriptBlock {
  # Failover Clustering
  Start-Transcript -Path C:\Windows\wsfclog.txt
  Install-Module az.storage -Force -Confirm:$false
  Add-WindowsFeature RSAT-Clustering-PowerShell

  # Variables
  $FeatureList = "Failover-Clustering"
  Connect-AzAccount -Tenant $Using:tenantid -Subscription $Using:subscriptionid -Credential $Using:creds -ServicePrincipal | Out-Null
  $accesskey = Get-AzStorageAccountKey -ResourceGroupName $witness_rg -Name $witnessaccountname

  # Install the role
  Invoke-Command ($Using:ServerList) {
    Install-WindowsFeature -Name $Featurelist -IncludeManagementTools
  }

  # Create the cluster
  Write-Host "Creating cluster"
  New-Cluster -Name $Using:clustername -Node $Using:ServerList -NoStorage -StaticAddress $Using:clusterip

  Start-Sleep -Seconds 60

  # Create cloud witness
  Write-Host "Setting Quorum"
  Set-ClusterQuorum -CloudWitness -AccountName $Using:witnessaccountname -AccessKey $accesskey.value[0] -Cluster $Using:clustername
  Stop-Transcript
}

Remove-Item -Path C:\Windows\Panther\unattend.xml -Force -Confirm:$false
