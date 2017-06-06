Function Get-F5AllPoolsUsingRESTAPi
{
    [cmdletbinding(DefaultParameterSetName='Partition')]
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='Partition')]
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='Exclusions')]
        [parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName='JsonObject')]
        [System.Management.Automation.CredentialAttribute()]$Credentials,
        [parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='Exclusions')]
        $PartitionExclusions = @(),
        [parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='Partition')]
        $TargetPartitions = @(),
        [parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName='JsonObject')]
        [switch]$JsonObject,
        [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,ParameterSetName='JsonObject')]
        [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,ParameterSetName='Partition')]
        [parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,ParameterSetName='Exclusions')]
        [string]$F5
        
    )
    Begin
    {
        $AllPoolsInfo = @()
    }
    Process
    {
        try
        {
            $GetAllF5Info = Invoke-WebRequest -Uri "https://$F5/mgmt/tm/ltm/pool/" -ContentType 'application/json' -Method Get -Credential $Credentials -ErrorAction Stop 
        }
        catch
        {
            Throw $($_.exception.message | Out-String)
        }
        if($GetAllF5Info.StatusDescription -eq 'OK')
        {
            if($JsonObject)
            {
                $AllPoolsInfo += $GetAllF5Info
                Write-Host "JsonObject"
            }
            else
            {
                $LinkProp = @{n='selfLink';e={((($_.selflink).split('?') | select -First 1).replace('localhost',"$F5"))}}
                $F5Prop = @{n='F5';e={$F5}}
                $PoolFullPathProp = @{n='PoolFullPath';e={$_.Fullpath}}
                $GetPools = $GetAllF5Info | ConvertFrom-Json | select -ExpandProperty items | select name,partition, $PoolFullPathProp, $LinkProp, $F5Prop
                if($PartitionExclusions)
                {
                    foreach($PartitionExclusion in $PartitionExclusions)
                    {
                        $GetPools = $GetPools | ? {$_.partition -notmatch $PartitionExclusion}  | select name,partition, PoolFullPath, selflink, F5
                    }
                    $AllPoolsInfo += $GetPools
                }
                elseif($TargetPartitions)
                {
                    $TargetedPartitions = @() 
                    foreach($TargetPartition in $TargetPartitions)
                    {
                        $TargetedPartitions += $GetPools | ? {$_.partition -match $TargetPartition}  | select name,partition, PoolFullPath, selflink, F5
                    }
                    $AllPoolsInfo += $TargetedPartitions
                }
                else
                {
                    $AllPoolsInfo += $GetPools | select name,partition, PoolFullPath, selflink, F5
                }
            }
        }
        else
        {
            Throw "Status Description from the last rest call was not ok."
        }
    }
    End
    {
        $AllPoolsInfo
    }
}
