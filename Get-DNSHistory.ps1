<#
.SYNOPSIS
    Returns dns history for a given domain and record type
.DESCRIPTION
    Returns dns history for a given domain and record type
.NOTES
    Requires an API key from https://securitytrails.com
.LINK
    https://docs.securitytrails.com/reference/history-dns
.EXAMPLE
    Get-DnsHistory -DomainName "google.com" -RecordType "A" -ApiKey "1234567890"
#>
function Get-DNSHistory {
    param (
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Type
    )
    $Type = $Type.ToLower()
    $URI = [System.UriBuilder]::new("https", "api.securitytrails.com", 443, "v1/history/$Domain/dns/$Type") 
    $Headers = @{
        "APIKEY" = $Key
    }
    try {
        $Response = Invoke-RestMethod -Uri $URI.Uri.AbsoluteUri -Headers $Headers -Method Get -ContentType "application/json"
    }
    catch {
        throw $_.Exception.Message
    }

    $return = [System.Collections.Generic.List[pscustomobject]]::new()
    $response.records | Foreach-Object { 
        if ($_.values.count -eq 0) {
            return
        }
        $o = [PSCustomObject]@{
            Domain    = $domain
            FirstSeen = $_.first_seen
            LastSeen  = $_.last_seen
            Type      = $_.type
        }
        if ($_.organizations.length -gt 0) {
            $o | Add-Member -MemberType NoteProperty -Name "Organization" -Value $_.organizations[0]
        }
        $i = 0
        if ($type -match "mx") {
            for ($i; $i -lt $_.values.Count) {
                $o | Add-Member -MemberType NoteProperty -Name "$($_.Type)$($i)" -Value $_.values[$i].host
                $i++
            }
            $return.Add($o)
        }
        $i = 0
        if ($Type -match "a") {
            for ($i; $i -lt $_.values.Count) {
                $o | Add-Member -MemberType NoteProperty -Name "$($_.Type)$($i)" -Value $_.values[$i].ip
                $i++
            }
            $return.Add($o)
        }
        $i = 0
        if ($type -match "ns") {
            for ($i; $i -lt $_.values.Count) {
                $o | Add-Member -MemberType NoteProperty -Name "$($_.Type)$($i)" -Value $_.values[$i].nameserver
                $i++
            }
            $return.Add($o)
        }
        if ($type -match "txt") {
            for ($i; $i -lt $_.values.Count) {
                $o | Add-Member -MemberType NoteProperty -Name "$($_.Type)$($i)" -Value $_.values[$i].value
                $i++
            }
            $return.Add($o)
        }
    }
    return $return | Sort-Object -Property FirstSeen
}

