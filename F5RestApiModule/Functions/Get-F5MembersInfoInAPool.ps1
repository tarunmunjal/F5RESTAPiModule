Function Get-F5MembersInfoInAPoolUsingRESTAPi
{
    [cmdletbinding(DefaultParameterSetName='Properties')]
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='JsonObject')]
        [System.Management.Automation.CredentialAttribute()]$Credentials,
        [parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
        [parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='JsonObject')]
        [string]$F5,
        [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true,ParameterSetName='Properties')]
        [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true,ParameterSetName='JsonObject')]
        [array]$PoolFullPath,
        [parameter(Mandatory=$false,ParameterSetName='JsonObject')]
        [switch]$JsonObject
    )
    Begin
    {
        add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $AllMembersInfo = @()
    }
    Process
    {
        foreach($PFullPath in $PoolFullPath)   
        {
            $Pool = $PFullPath -replace '/','~'
            try
            {
                $membersinfo = Invoke-WebRequest -Uri "https://$F5/mgmt/tm/ltm/pool/$Pool/members" -Credential $Credentials -ContentType 'application/json' -Method Get -ErrorAction Stop
            }
            catch
            {
                Throw $($_.exception.message | Out-String)
            }
            if($JsonObject.IsPresent)
            {
                $AllMembersInfo += $membersinfo
            }
            else
            {
                $membersinfo = $membersinfo | ConvertFrom-Json | select -ExpandProperty items
                foreach($memberinfo in $membersinfo)
                {
                    $OneMemberInfo = New-Object -TypeName psobject -Property @{
                        Partition = $memberinfo | select -ExpandProperty partition
                        PoolFullPath = $PFullPath
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
        }
    }
    End
    {
        $AllMembersInfo
    }
}
