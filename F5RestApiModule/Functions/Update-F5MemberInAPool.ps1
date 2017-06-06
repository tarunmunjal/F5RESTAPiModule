Function Update-F5MemberInAPool
{
    [cmdletbinding(DefaultParameterSetName='Enable')]
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Enable')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Offline')]
    [string]$F5,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Enable')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Offline')]
    [string]$PoolFullPath,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Enable')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Offline')]
    [string]$MemberFullPath,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='MemberResourceUrl')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Enable')]
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='Offline')]
    [string]$MemberSelfLink,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='MemberResourceUrl')]
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Enable')]
    [switch]$Enable,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='MemberResourceUrl')]
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Offline')]
    [switch]$Offline,
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [System.Management.Automation.CredentialAttribute()]$Credentials,
    #[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    #[ValidateSet("user-up","user-down")]
    #[string]$State,
    #[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    #[ValidateSet("user-enabled","user-disabled")]
    #[string]$Session,
    [Parameter(Mandatory=$false)]
    [switch]$JsonObject
    )
    Begin
    {
        $AllMembersInfo = @()
        $StatusJsonBody = @{}
        $StatusJsonBody.add('state','')
        $StatusJsonBody.add('session','')
        if($Offline.IsPresent)
        {
            $State = 'user-down'
            $Session = 'user-disabled'
        }
        if($Enable.IsPresent)
        {
            $State = 'user-up'
            $Session = 'user-enabled'
        }
    }
    Process
    {
        $StatusJsonBody.state = $State
        $StatusJsonBody.session = $Session
        if(-not $MemberResourceUrl)
        {
            $PoolFullPath = $PoolFullPath -replace '/','~'
            $MemberFullPath = $MemberFullPath -replace '/','~'
            $ResourceUri = "https://$F5/mgmt/tm/ltm/pool/$PoolFullPath/members/$MemberFullPath"
        }
        else
        {
            #CAPS in exapmple represent values that need to be changed smalls are all static
            #Example "https://F5ADDRESS/mgmt/tm/ltm/pool/~PARTITIONNAME~POOLNAME/members/~PARTITIONNAME~MEMBERADDRESS"
            $ResourceUri = $MemberResourceUrl
        }
        $PatchResults = Invoke-WebRequest -Method Patch -Uri "$ResourceUri" -Credential $Credentials -Body ($StatusJsonBody | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop
        if($JsonObject)
        {
            $AllMembersInfo += $PatchResults
        }
        else
        {
            $memberinfo = $PatchResults | ConvertFrom-Json
            $OneMemberInfo = New-Object -TypeName psobject -Property @{
                Partition = $memberinfo | select -ExpandProperty partition
                PoolFullPath = $PoolFullPath
                MemberAddress = $memberinfo | select -ExpandProperty address
                MemberName =  $memberinfo | select -ExpandProperty  name
                MemberFullPath = $memberinfo | select  -ExpandProperty fullpath
                MemberSession = $memberinfo | select  -ExpandProperty session
                MemberState = $memberinfo | select  -ExpandProperty state
                F5 = $F5
            }
            $OneMemberInfo.MemberAddress = Get-ValidIPAddressFromString -InputStrings $OneMemberInfo.memberaddress 
            $AllMembersInfo += $OneMemberInfo
        }
    } 
    End
    {
        $AllMembersInfo      
    }
}
