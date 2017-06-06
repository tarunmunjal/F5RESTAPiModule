Function Compare-F5ActivePassive
{
    [cmdletbinding()]
    Param(
    [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [string]$F5Active =  'F51Address' ,
    [parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
    [string]$F5Passive =  'F52Address' ,
    [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true)]
    [System.Management.Automation.CredentialAttribute()]$Credential
    )
    Begin
    {
        Import-Module C:\BitBucket\F5RESTModule.ps1 -Force
    }
    Process
    {
        $ActiveResults = $F5Active | Get-F5AllPoolsUsingRESTAPi -Credentials $Credentials -ErrorAction Stop | Get-F5MembersInfoInAPoolUsingRESTAPi -Credentials $Credentials -ErrorAction Stop
        $PassiveResults = $F5Passive | Get-F5AllPoolsUsingRESTAPi -Credentials $Credentials  -ErrorAction Stop | Get-F5MembersInfoInAPoolUsingRESTAPi -Credentials $Credentials -ErrorAction Stop
        $ComparisonResults = Compare-Object -ReferenceObject $ActiveResults -DifferenceObject $PassiveResults -Property MemberSession,MemberState,MemberName,MemberAddress,MemberFullPath,PoolFullPath,Partition -ErrorAction Stop -IncludeEqual
    }
    End
    {
        $CombinedResult = $ComparisonResults | select MemberSession,MemberState,MemberName,MemberAddress,MemberFullPath,PoolFullPath,Partition,SideIndicator,@{N='F5s';E={"$F5Active,$F5Passive"}}
        $CombinedResult
    }

}